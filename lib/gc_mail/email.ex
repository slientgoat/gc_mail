defmodule GCMail.Email do
  use Ecto.Schema
  @primary_key false
  @type id :: integer()
  schema "email" do
    field(:mail_id, :integer, primary_key: true)
    field(:to, :integer, primary_key: true)
  end
end
