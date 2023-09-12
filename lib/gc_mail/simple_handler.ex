defmodule GCMail.SimpleHandler do
  @behaviour GCMail.Behaviour

  def save_mails(mails) do
    mails = Enum.map(mails, &Map.put(&1, :id, System.unique_integer([:positive])))
    {:ok, mails}
  end

  def save_emails(mails) do
    mails = Enum.map(mails, &Map.put(&1, :id, System.unique_integer([:positive])))
    {:ok, mails}
  end
end
