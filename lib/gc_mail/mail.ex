defmodule GCMail.Mail do
  use Ecto.Schema
  import Ecto.Changeset

  import EctoCustomValidator
  @primary_key {:id, :id, autogenerate: true}
  @type id :: integer()
  schema "mail" do
    field(:mail_type, GCMail.Enums.MailType)
    field(:cfg_id, :integer)
    field(:title, :string)
    field(:body, :string)
    field(:args, {:array, :string})
    field(:attaches, {:array, :integer})
    field(:create_time, :integer)
    field(:trigger_time, :integer)
    field(:retention_time, :integer)
    field(:from, :string)
    field(:to, {:array, :integer})
  end

  @system_mail_fields ~w(mail_type cfg_id args attaches create_time trigger_time retention_time from to)a
  @system_mail_required_fields ~w(mail_type cfg_id)a
  def system_mail_changeset(mail, attrs) do
    mail
    |> cast(attrs, @system_mail_fields)
    |> validate_required(@system_mail_required_fields)
    |> validate_args()
    |> validate_attaches()
  end

  def validate_args(changeset) do
    changeset
    |> validate_length(:args, min: 0, max: 100)
  end

  def validate_attaches(changeset) do
    changeset
    |> validate_length(:attaches, min: 0, max: 100)
    |> validate_list_length_is_even(:attaches)
  end
end
