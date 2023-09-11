defmodule GCMail.RoleMail do
  use Ecto.Schema
  @primary_key false
  @type id :: integer()
  schema "mail" do
    field(:role_id, :integer, primary_key: true)
    field(:mail_id, :integer, primary_key: true)
  end
end
