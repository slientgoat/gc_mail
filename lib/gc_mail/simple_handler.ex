defmodule GCMail.SimpleHandler do
  @behaviour GCMail.Behaviour

  @ets_mail Module.concat(__MODULE__, Mail)
  @ets_role_mail Module.concat(__MODULE__, PersonalMail)
  def init() do
    :ets.new(@ets_mail, [
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    :ets.new(@ets_role_mail, [
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

  def save_role_mails(mails) do
    mails = Enum.map(mails, &Map.put(&1, :id, System.unique_integer([:positive])))
    {:ok, mails}
  end

  def cache_mails(mails) do
    Enum.map(mails, &:ets.insert(@ets_mail, {&1.id, &1}))
    :ok
  end

  def cache_role_mails(mails) do
    Enum.map(mails, &:ets.insert(@ets_role_mail, {&1.id, &1}))
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

  def lookup_role_mails(to) do
    :ets.lookup(@ets_role_mail, to)
    |> case do
      [] ->
        nil

      role_mails ->
        role_mails
    end
  end
end
