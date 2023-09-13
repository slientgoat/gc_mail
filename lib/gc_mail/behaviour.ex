defmodule GCMail.Behaviour do
  @callback save_mails(list(GCMail.Mail.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.Mail.t())}
  @callback save_emails(list(GCMail.Email.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.Email.t())}

  @callback cast_email_id(GCMail.Email.t()) :: GCMail.Email.t()

  @optional_callbacks [cast_email_id: 1]
end
