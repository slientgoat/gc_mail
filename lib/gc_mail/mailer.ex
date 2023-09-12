defmodule GCMail.Mailer do
  use GenServer
  alias GCMail.Mailer, as: M
  alias GCMail.Mail
  import ShorterMaps
  require Logger

  defstruct id: nil, loop_interval: nil, prepare_mails: [], personal_mail_ids: [], handler: nil

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

  def handle_continue(:initialize, ~M{%M id,handler} = state) do
    if id == 1 do
      handler.init()
    end

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
        ~M{%M handler,prepare_mails,loop_interval,personal_mail_ids} = state
      ) do
    with {:ok, prepare_mails, new_mail_ids} <- handle_prepare_mails(handler, prepare_mails) do
      personal_mail_ids = new_mail_ids ++ personal_mail_ids

      if personal_mail_ids != [] do
        loop_handle_personal_mail_ids()
      end

      loop_handle_prepare_mails(loop_interval)

      {:noreply, ~M{state|prepare_mails,personal_mail_ids}}
    else
      _ ->
        loop_handle_prepare_mails(loop_interval)
        {:noreply, state}
    end
  end

  def handle_info(:loop_handle_personal_mail_ids, ~M{%M handler,personal_mail_ids} = state) do
    with {:ok, personal_mail_ids} <-
           handle_personal_mail_ids(handler, personal_mail_ids) do
      loop_handle_personal_mail_ids()
      {:noreply, ~M{state|personal_mail_ids}}
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
         :ok <- handler.cache_mails(mails) do
      personal_mail_ids = take_personal_mail_ids(mails)
      {:ok, rest, personal_mail_ids}
    else
      _e ->
        :ignore
    end
  end

  defp take_personal_mail_ids(mails) do
    mails
    |> Enum.map(fn x ->
      List.wrap(x.to) |> Enum.map(&{&1, x.id})
    end)
    |> Enum.concat()
  end

  defp loop_handle_prepare_mails(loop_interval) do
    Process.send_after(self(), :loop_handle_prepare_mails, loop_interval)
  end

  defp handle_personal_mail_ids(handler, mail_ids) do
    {mail_ids, rest} = mail_ids |> Enum.reverse() |> Enum.split(@batch_num)

    with {:ok, mail_ids} <- handler.save_role_mails(mail_ids),
         :ok <- handler.cache_role_mails(mail_ids) do
      {:ok, rest}
    else
      _e ->
        :ignore
    end
  end

  defp loop_handle_personal_mail_ids(loop_interval \\ 100) do
    Process.send_after(self(), :loop_handle_personal_mail_ids, loop_interval)
  end
end
