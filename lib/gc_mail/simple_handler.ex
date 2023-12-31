defmodule GCMail.SimpleHandler do
  use GCMail, ttl: 999
  require Logger

  @impl true
  def dump_mails(mails) when is_list(mails) do
    mails = Enum.map(mails, &Map.put(&1, :id, System.unique_integer([:positive])))
    Process.sleep(50)
    {:ok, mails}
  end

  @impl true
  def dump_emails(emails) when is_list(emails) do
    Process.sleep(50)
    {:ok, emails}
  end

  @impl true
  def cast_email(%GCMail.Email{mail_id: mail_id, to: to} = email) do
    Map.put(email, :id, "#{to}|#{mail_id}")
  end

  @impl true
  def on_callback_fail(_fun, _arg, _error) do
    # Logger.error(fun: fun, arg: arg, error: error)
    :ok
  end
end
