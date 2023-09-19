defmodule GCMail.Behaviour do
  @type callback_fun ::
          :dump_mails
          | :dump_emails
          | :load_mails
          | :load_emails
          | :on_handle_mail_success
          | :on_handle_email_success
          | :cast_email_id
  @callback dump_mails(list(GCMail.Mail.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.Mail.t())}
  @callback dump_emails(list(GCMail.Email.t())) ::
              {:error, Ecto.Changeset.t()} | {:ok, list(GCMail.Email.t())}

  @callback load_mails() :: list(GCMail.Mail.t())
  @callback load_emails() :: list(GCMail.Email.t())

  @callback on_handle_mail_success([GCMail.Mail.t()]) :: :ok
  @callback on_handle_email_success([GCMail.Email.t()]) :: :ok
  @callback on_callback_fail(fun :: callback_fun(), arg :: any(), reason :: any()) :: :ok
  @callback cast_email(GCMail.Email.t()) :: GCMail.Email.t()

  @optional_callbacks [
    cast_email: 1,
    on_handle_email_success: 1,
    on_handle_mail_success: 1
  ]
end
