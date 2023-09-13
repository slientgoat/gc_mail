defmodule GCMail.Email do
  use Ecto.Schema
  @primary_key false
  @primary_key {:id, :id, autogenerate: true}
  @type id :: integer()
  schema "email" do
    field(:to, :integer)
    field(:mail_id, :integer)
  end
end
