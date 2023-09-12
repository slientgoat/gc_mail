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

  @spec deliver(mail :: %GCMail.Mail{}) :: :ok
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

  def handle_continue(:initialize, ~M{%M } = state) do
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

  def handle_info(
        :loop_handle_prepare_mails,
        ~M{%M handler,prepare_mails,loop_interval,prepare_emails} = state
      ) do
    with {:ok, prepare_mails, new_mail_ids} <- handle_prepare_mails(handler, prepare_mails) do
      prepare_emails = new_mail_ids ++ prepare_emails

      if prepare_emails != [] do
        loop_handle_prepare_emails()
      end

      loop_handle_prepare_mails(loop_interval)

      {:noreply, ~M{state|prepare_mails,prepare_emails}}
    else
      _ ->
        loop_handle_prepare_mails(loop_interval)
        {:noreply, state}
    end
  end

  def handle_info(:loop_handle_prepare_emails, ~M{%M handler,prepare_emails} = state) do
    with {:ok, prepare_emails} <-
           handle_prepare_emails(handler, prepare_emails) do
      loop_handle_prepare_emails()
      {:noreply, ~M{state|prepare_emails}}
    else
      _ ->
        {:noreply, state}
    end
  end

  def handle_info(event, state) do
    Logger.error(event_not_handle: event)
    {:noreply, state}
  end

  defp handle_prepare_mails(handler, prepare_mails) do
    {mails, rest} = prepare_mails |> Enum.reverse() |> Enum.split(@batch_num)

    with {:ok, mails} <- handler.save_mails(mails),
         :ok <- cache_mails(mails) do
      prepare_emails = make_prepare_emails(mails)
      {:ok, rest, prepare_emails}
    else
      _e ->
        :ignore
    end
  end

  def cache_mails(mails) do
    Enum.map(mails, &{&1.id, &1})
    |> GCMail.MailCache.put_all()
  end

  def make_prepare_emails(mails) do
    mails
    |> Enum.map(fn x ->
      List.wrap(x.targets) |> Enum.map(&{&1, x.id})
    end)
    |> Enum.concat()
  end

  defp loop_handle_prepare_mails(loop_interval) do
    Process.send_after(self(), :loop_handle_prepare_mails, loop_interval)
  end

  defp handle_prepare_emails(handler, prepare_emails) do
    with {prepare_emails, rest} <- take_prepare_emails(prepare_emails),
         {:ok, prepare_emails} <- handler.save_emails(prepare_emails),
         :ok <- cache_emails(prepare_emails) do
      {:ok, rest}
    else
      _e ->
        :ignore
    end
  end

  def cache_emails(emails) do
    Enum.map(emails, fn {to, mail_id} = e -> {"#{to}|#{mail_id}", e} end)
    |> GCMail.EmailCache.put_all()
  end

  defp loop_handle_prepare_emails(loop_interval \\ 100) do
    Process.send_after(self(), :loop_handle_prepare_emails, loop_interval)
  end

  def take_prepare_emails(prepare_emails) do
    prepare_emails |> Enum.reverse() |> Enum.split(@batch_num)
  end
end
