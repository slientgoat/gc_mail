defmodule GCMail.Mail do
  use Ecto.Schema
  import Ecto.Changeset
  alias GCMail.Type
  import EctoCustomValidator
  alias GCMail.Mail, as: M
  @primary_key {:id, :id, autogenerate: true}
  @type id :: integer()
  schema "mail" do
    field(:type, Type)
    field(:from, :string)
    field(:targets, {:array, :integer})
    field(:cfg_id, :integer)
    field(:title, :string)
    field(:body, :string)
    field(:assigns, {:map, :string})
    field(:attaches, {:array, :integer})
    field(:send_at, :integer)
    field(:trigger_at, :integer)
    field(:ttl, :integer)
  end

  @required_fields ~w(type send_at ttl)a
  @global_system_mail_fields ~w(type from cfg_id assigns attaches send_at trigger_at ttl)a
  @personal_system_mail_fields ~w(type from targets cfg_id assigns attaches send_at trigger_at ttl)a
  @system_mail_required_fields ~w(cfg_id)a

  @spec validate_global_system_mail_attrs(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def validate_global_system_mail_attrs(attrs) do
    attrs
    |> setup_common_attrs(@global_system_mail_fields)
    |> validate_inclusion(:type, [Type.GlobalSystem])
    |> validate_required(@system_mail_required_fields)
    |> apply_action(:validate)
  end

  defp setup_common_attrs(attrs, fields) do
    attrs
    |> ensure_common_attrs()
    |> then(&cast(%M{}, &1, fields))
    |> validate_assigns()
    |> validate_attaches()
    |> validate_required(@required_fields)
  end

  defp ensure_common_attrs(attrs) do
    attrs
    |> ensure_key_exist(:ttl, default_ttl())
    |> ensure_key_exist(:send_at, System.os_time(:second))
  end

  def default_ttl(), do: 90 * 86400

  defp ensure_key_exist(attrs, key, default) do
    Enum.into(attrs, Map.new([{key, default}]))
  end

  defp validate_assigns(changeset) do
    changeset
    |> validate_length(:assigns, min: 0, max: max_assigns_length())
  end

  def max_assigns_length(), do: 100

  defp validate_attaches(changeset) do
    changeset
    |> validate_length(:attaches, min: 0, max: max_attaches_length())
    |> validate_list_length_is_even(:attaches)
  end

  def max_attaches_length(), do: 100
end
