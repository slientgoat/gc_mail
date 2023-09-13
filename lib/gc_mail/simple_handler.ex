defmodule GCMail.SimpleHandler do
  use GCMail

  @impl true
  def save_mails(mails) do
    mails = Enum.map(mails, &Map.put(&1, :id, System.unique_integer([:positive])))
    {:ok, mails}
  end

  @impl true
  def save_emails(emails) do
    {:ok, emails}
  end

  @impl true
  def cast_email_id(%GCMail.Email{mail_id: mail_id, to: to} = email) do
    Map.put(email, :id, "#{to}|#{mail_id}")
  end
end
