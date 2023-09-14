defmodule GCMail.Mail do
  use EnumType

  defenum Type do
    value(PersonalSystem, 1)
    value(PersonalCustom, 2)
    value(GlobalSystem, 3)
    value(GlobalCustom, 4)
    default(PersonalCustom)

    def personal, do: [PersonalSystem, PersonalCustom]
    def global, do: [GlobalSystem, GlobalCustom]
    def system, do: [GlobalSystem, PersonalSystem]
    def custom, do: [GlobalCustom, PersonalCustom]
  end

  use Ecto.Schema
  import Ecto.Changeset
  import EctoCustomValidator
  alias GCMail.Mail, as: M
  @primary_key {:id, :id, autogenerate: true}
  @type id :: integer()
  schema "mail" do
    field(:type, Type)
    field(:from, :string)
    field(:cfg_id, :integer)
    field(:title, :string)
    field(:body, :string)
    field(:targets, {:array, :integer})
    field(:assigns, {:map, :string})
    field(:attaches, {:array, :integer})
    field(:send_at, :integer)
    field(:trigger_at, :integer)
    field(:ttl, :integer)
  end

  @common_fields ~w(type from assigns attaches send_at trigger_at ttl)a

  @require_fields %{
    Type.GlobalSystem => [:cfg_id],
    Type.PersonalSystem => [:cfg_id, :targets],
    Type.GlobalCustom => [:title, :body],
    Type.PersonalCustom => [:title, :body, :targets]
  }

  @cast_fields for t <- Type.enums(), into: %{}, do: {t, @require_fields[t] ++ @common_fields}

  def require_fields(), do: @require_fields
  def cast_fields(), do: @cast_fields

  def validate(fun, attrs) do
    %M{}
    |> cast(
      attrs,
      ~w(type from cfg_id title body targets assigns attaches send_at trigger_at ttl)a
    )
    |> then(&apply(fun, [&1]))
    |> apply_action(:validate)
  end

  @spec validate_global_system_mail_attrs(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def validate_global_system_mail_attrs(attrs) do
    validate_attrs(attrs, Type.GlobalSystem)
    |> apply_action(:validate)
  end

  @spec validate_personal_system_mail_attrs(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def validate_personal_system_mail_attrs(attrs) do
    validate_attrs(attrs, Type.PersonalSystem)
    |> validate_targets()
    |> apply_action(:validate)
  end

  @spec validate_global_custom_mail_attrs(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def validate_global_custom_mail_attrs(attrs) do
    validate_attrs(attrs, Type.GlobalCustom)
    |> validate_title()
    |> validate_body()
    |> apply_action(:validate)
  end

  @spec validate_personal_custom_mail_attrs(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def validate_personal_custom_mail_attrs(attrs) do
    validate_attrs(attrs, Type.PersonalCustom)
    |> validate_title()
    |> validate_body()
    |> validate_targets()
    |> apply_action(:validate)
  end

  defp validate_attrs(attrs, type) do
    cast_fields = @cast_fields[type]
    required_fields = @require_fields[type]

    attrs
    |> setup_common_attrs(cast_fields)
    |> validate_inclusion(:type, [type])
    |> validate_required(required_fields)
  end

  @required_fields ~w(type send_at ttl)a
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

  def validate_assigns(changeset) do
    changeset
    |> validate_length(:assigns, min: 0, max: max_assigns_length())
  end

  def max_assigns_length(), do: 100

  def validate_attaches(changeset) do
    changeset
    |> validate_length(:attaches, min: 0, max: max_attaches_length())
    |> validate_list_length_is_even(:attaches)
  end

  def max_attaches_length(), do: 100

  def validate_title(changeset) do
    changeset
    |> validate_length(:title, min: 0, max: max_title_length())
  end

  def max_title_length(), do: 200

  def validate_body(changeset) do
    changeset
    |> validate_length(:body, min: 0, max: max_body_length())
  end

  def max_body_length(), do: 4000

  def validate_targets(changeset) do
    changeset
    |> validate_length(:targets, min: 1, max: max_targets_length())
  end

  def max_targets_length(), do: 10000
end
