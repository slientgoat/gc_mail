defmodule GCMail.SimpleHandler do
  @behaviour GCMail.Behaviour

  @ets_mail Module.concat(__MODULE__, Mail)
  @ets_email Module.concat(__MODULE__, Email)
  def init() do
    :ets.new(@ets_mail, [
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(@ets_email, [
      :named_table,
      :set,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ok
  end

  def save_mails(mails) do
    mails = Enum.map(mails, &Map.put(&1, :id, System.unique_integer([:positive])))
    {:ok, mails}
  end

  def save_emails(mails) do
    mails = Enum.map(mails, &Map.put(&1, :id, System.unique_integer([:positive])))
    {:ok, mails}
  end

  def cache_mails(mails) do
    Enum.map(mails, &:ets.insert(@ets_mail, {&1.id, &1}))
    :ok
  end

  def cache_emails(mails) do
    Enum.map(mails, &:ets.insert(@ets_email, {&1.id, &1}))
    :ok
  end

  def get_mail(mail_id) do
    :ets.lookup(@ets_mail, mail_id)
    |> case do
      [{_, mail}] ->
        mail

      _ ->
        nil
    end
  end

  def lookup_emails(to) do
    :ets.lookup(@ets_email, to)
    |> case do
      [] ->
        nil

      emails ->
        emails
    end
  end
end
