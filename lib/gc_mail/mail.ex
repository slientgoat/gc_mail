defmodule GCMail.Mail do
  use Ecto.Schema
  import Ecto.Changeset

  import EctoCustomValidator
  @primary_key {:id, :id, autogenerate: true}
  @type id :: integer()
  schema "mail" do
    field(:type, GCMail.Type)
    field(:from, :string)
    field(:to, {:array, :integer})
    field(:cfg_id, :integer)
    field(:title, :string)
    field(:body, :string)
    field(:assigns, {:array, :string})
    field(:attaches, {:array, :integer})
    field(:send_at, :integer)
    field(:trigger_at, :integer)
    field(:ttl, :integer)
  end

  @required_fields ~w(type send_at)a
  @system_mail_fields ~w(type cfg_id assigns attaches send_at trigger_at ttl from to)a
  @system_mail_required_fields @required_fields ++ ~w(cfg_id)a
  def system_mail_changeset(mail, attrs) do
    mail
    |> cast(attrs, @system_mail_fields)
    |> validate_inclusion(:type, GCMail.Type.system())
    |> validate_required(@system_mail_required_fields)
    |> validate_assigns()
    |> validate_attaches()
  end

  def validate_assigns(changeset) do
    changeset
    |> validate_length(:assigns, min: 0, max: 100)
  end

  def validate_attaches(changeset) do
    changeset
    |> validate_length(:attaches, min: 0, max: 100)
    |> validate_list_length_is_even(:attaches)
  end
end
