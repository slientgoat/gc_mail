defmodule GCMail.Behaviour do
  @callback init() :: :ok
  @callback save_mails(list(GCMail.Mail.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.Mail.t())}
  @callback save_role_mails(list(GCMail.RoleMail.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.RoleMail.t())}
  @callback cache_mails(list(GCMail.Mail.t())) :: :ok
  @callback cache_role_mails(list(GCMail.RoleMail.t())) :: :ok
  @callback get_mail(integer) :: nil | GCMail.Mail.t()
  @callback lookup_role_mails(role_id :: integer) :: [{integer(), GCMail.RoleMail.id()}]
end
