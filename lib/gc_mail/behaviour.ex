defmodule GCMail.Behaviour do
  @callback init() :: :ok
  @callback save_mails(list(GCMail.Mail.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.Mail.t())}
  @callback save_emails(list(GCMail.Email.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.Email.t())}
  @callback cache_mails(list(GCMail.Mail.t())) :: :ok
  @callback cache_emails(list(GCMail.Email.t())) :: :ok
  @callback get_mail(integer) :: nil | GCMail.Mail.t()
  @callback lookup_emails(role_id :: integer) :: [{integer(), GCMail.Email.id()}]
end
