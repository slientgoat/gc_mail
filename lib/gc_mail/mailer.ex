defmodule GCMail.Mailer do
  use GenServer
  alias GCMail.Mailer, as: M
  alias GCMail.Mail

  import ShorterMaps

  defstruct id: nil, loop_interval: nil, prepare_mails: [], prepare_emails: [], handler: nil

  @worker_num System.schedulers_online()
  @loop_intervals Enum.to_list(0..@worker_num) |> Enum.map(&(200 + &1 * 10)) |> List.to_tuple()
  @batch_num 1000

  def batch_num, do: @batch_num

  @spec deliver(%GCMail.Mail{}) :: :ok
  def deliver(mail) do
    cast(mail.send_at, {:deliver, mail})
  end

  def call(key, event) do
    choose_worker(key) |> GenServer.call(event)
  end

  def cast(key, event) do
    choose_worker(key) |> GenServer.cast(event)
  end

  def choose_worker(key) do
    # (:erlang.phash2("#{key}", @worker_num) + 1) |> via()
    key
    |> :erlang.phash2()
    |> :jchash.compute(@worker_num - 1)
    |> via()
  end

  def start_args(opts) do
    for id <- 1..@worker_num do
      {__MODULE__, [{:id, id} | opts]}
    end
  end

  def child_spec(opts) do
    id = opts[:id]

    %{
      id: via(id),
      start: {__MODULE__, :start_link, [opts]},
      shutdown: 5_000,
      restart: :permanent,
      type: :worker
    }
  end

  def start_link(opts) do
    id = opts[:id]

    GenServer.start_link(__MODULE__, opts, name: via(id))
  end

  def via(id) do
    Module.concat(__MODULE__, "#{id}")
  end

  def init(opts) do
    id = opts[:id]
    handler = opts[:handler]

    loop_interval = elem(@loop_intervals, id)
    {:ok, %M{id: id, loop_interval: loop_interval, handler: handler}, {:continue, :initialize}}
  end

  def handle_continue(:initialize, ~M{%M id,handler,loop_interval} = state) do
    if id == 1 do
      load_mails_to_cache(handler)
      load_emails_to_cache(handler)
    end

    loop_handle_prepare_mails(loop_interval)
    loop_handle_prepare_emails(loop_interval + 50)
    {:noreply, state}
  end

  defp load_mails_to_cache(handler) do
    load_mails(handler)
    |> cache_mails()
  end

  def load_emails_to_cache(handler) do
    load_emails(handler)
    |> cache_emails()
  end

  def handle_cast({:deliver, mail}, ~M{%M prepare_mails} = state) do
    with true <- is_struct(mail, Mail) do
      {:noreply, %{state | prepare_mails: [mail | prepare_mails]}}
    else
      _ ->
        {:noreply, state}
    end
  end

  def handle_cast(_event, state) do
    {:noreply, state}
  end

  def handle_info(:loop_handle_prepare_mails, ~M{%M loop_interval} = state) do
    state = handle_prepare_mails(state)
    loop_handle_prepare_mails(loop_interval)
    {:noreply, state}
  end

  def handle_info(:loop_handle_prepare_emails, ~M{%M } = state) do
    state = handle_prepare_emails(state)
    loop_handle_prepare_emails()
    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  def handle_prepare_mails(~M{%M handler,prepare_mails,prepare_emails} = state) do
    with true <- prepare_mails != [],
         {prepare_mails, tails} <- Enum.split(prepare_mails, -@batch_num),
         {:ok, mails} <- dump_mails(handler, tails),
         :ok <- cache_mails(mails) do
      prepare_emails =
        make_prepare_emails(mails)
        |> Enum.concat(prepare_emails)

      if function_exported?(handler, :on_handle_mail_success, 1) do
        exec_callback(handler, :on_handle_mail_success, mails)
      end

      ~M{state|prepare_mails,prepare_emails}
    else
      _e ->
        state
    end
  end

  defp dump_mails(handler, tails) do
    exec_callback(handler, :dump_mails, tails)
  end

  defp load_mails(handler) do
    exec_callback(handler, :load_mails)
  end

  def make_prepare_emails(mails) do
    for %Mail{id: id, targets: targets} when targets != nil <- mails do
      targets |> Enum.map(&{&1, id})
    end
    |> Enum.concat()
  end

  @spec cache_mails(any) :: :ok
  def cache_mails(mails) do
    Enum.map(mails, &{&1.id, &1})
    |> GCMail.MailCache.put_all()
  end

  defp loop_handle_prepare_mails(loop_interval) do
    Process.send_after(self(), :loop_handle_prepare_mails, loop_interval)
  end

  def handle_prepare_emails(~M{%M handler,prepare_emails} = state) do
    with true <- prepare_emails != [] || :ignore,
         {prepare_emails, tails} <- Enum.split(prepare_emails, -@batch_num),
         {:ok, emails} <- dump_emails(handler, tails),
         :ok <- cache_emails(emails) do
      if function_exported?(handler, :on_handle_email_success, 1) do
        exec_callback(handler, :on_handle_email_success, emails)
      end

      ~M{state|prepare_emails}
    else
      _e ->
        state
    end
  end

  def dump_emails(handler, tails) do
    exec_callback(
      handler,
      :dump_emails,
      cast_emails(handler, tails)
    )
  end

  defp load_emails(handler) do
    exec_callback(handler, :load_emails)
  end

  @spec cache_emails(list(%GCMail.Email{})) :: :ok
  def cache_emails(emails) do
    Enum.map(emails, &{&1.id, &1})
    |> GCMail.EmailCache.put_all()
  end

  defp loop_handle_prepare_emails(loop_interval \\ 100) do
    Process.send_after(self(), :loop_handle_prepare_emails, loop_interval)
  end

  defp cast_emails(handler, prepare_emails) do
    if function_exported?(handler, :cast_email, 1) do
      for {to, mail_id} <- prepare_emails do
        exec_callback(
          handler,
          :cast_email,
          GCMail.Email.build_email(%{to: to, mail_id: mail_id})
        )
      end
    else
      for {to, mail_id} <- prepare_emails do
        GCMail.Email.build_email(%{to: to, mail_id: mail_id})
      end
    end
  end

  def exec_callback(handler, fun) do
    exec_callback(handler, fun, nil)
  end

  def exec_callback(handler, fun, arg) do
    try do
      if arg != nil do
        apply(handler, fun, [arg])
      else
        apply(handler, fun, [])
      end
    rescue
      error ->
        handler.on_callback_fail(fun, arg, error)
        {:error, error}
    catch
      error ->
        handler.on_callback_fail(fun, arg, error)
        {:error, error}
    end
  end
end
