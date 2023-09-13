defmodule GCMail.Mailer do
  use GenServer
  alias GCMail.Mailer, as: M
  alias GCMail.Mail

  import ShorterMaps
  require Logger

  defstruct id: nil, loop_interval: nil, prepare_mails: [], prepare_emails: [], handler: nil

  @worker_num 8
  @loop_intervals Enum.to_list(0..@worker_num) |> Enum.map(&(3000 + &1 * 10)) |> List.to_tuple()
  @batch_num 200

  @spec batch_num :: 200
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
    (:erlang.phash2("#{key}", @worker_num) + 1) |> via()
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

  def handle_continue(:initialize, ~M{%M loop_interval} = state) do
    loop_handle_prepare_mails(loop_interval)
    loop_handle_prepare_emails()
    {:noreply, state}
  end

  def handle_cast({:deliver, mail}, ~M{%M prepare_mails} = state) do
    with true <- is_struct(mail, Mail) do
      {:noreply, %{state | prepare_mails: [mail | prepare_mails]}}
    else
      _ ->
        {:noreply, state}
    end
  end

  def handle_cast(event, state) do
    Logger.error(event_not_handle: event)
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

  def handle_info(event, state) do
    Logger.error(event_not_handle: event)
    {:noreply, state}
  end

  def handle_prepare_mails(~M{%M handler,prepare_mails,prepare_emails} = state) do
    with true <- prepare_mails != [],
         {prepare_mails, tails} <- Enum.split(prepare_mails, -@batch_num),
         {:ok, mails} <- handler.save_mails(tails),
         :ok <- cache_mails(mails) do
      prepare_emails =
        make_prepare_emails(mails)
        |> Enum.concat(prepare_emails)

      ~M{state|prepare_mails,prepare_emails}
    else
      _e ->
        state
    end
  end

  def make_prepare_emails(mails) do
    for %Mail{id: id, targets: targets} when targets != nil <- mails do
      targets |> Enum.map(&{&1, id})
    end
    |> Enum.concat()
  end

  defp cache_mails(mails) do
    Enum.map(mails, &{&1.id, &1})
    |> GCMail.MailCache.put_all()
  end

  defp loop_handle_prepare_mails(loop_interval) do
    Process.send_after(self(), :loop_handle_prepare_mails, loop_interval)
  end

  def handle_prepare_emails(~M{%M handler,prepare_emails} = state) do
    with true <- prepare_emails != [] || :ignore,
         {prepare_emails, tails} <- Enum.split(prepare_emails, -@batch_num),
         {:ok, emails} <- handler.save_emails(convert_to_emails(handler, tails)),
         :ok <- cache_emails(emails) do
      ~M{state|prepare_emails}
    else
      _e ->
        state
    end
  end

  @spec cache_emails(list(%GCMail.Email{})) :: :ok
  def cache_emails(emails) do
    Enum.map(emails, &{&1.id, &1})
    |> GCMail.EmailCache.put_all()
  end

  defp loop_handle_prepare_emails(loop_interval \\ 100) do
    Process.send_after(self(), :loop_handle_prepare_emails, loop_interval)
  end

  defp convert_to_emails(handler, prepare_emails) do
    for {to, mail_id} <- prepare_emails do
      GCMail.Builder.new_email(%{to: to, mail_id: mail_id})
      |> handler.cast_email_id()
    end
  end
end
