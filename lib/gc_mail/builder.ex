defmodule GCMail.Builder do
  alias GCMail.Mail
  @default_retention_time 90 * 86400
  def default_retention_time(), do: @default_retention_time

  @callback cfg_ids() :: list(integer())
  def cfg_ids() do
    [System.unique_integer([:positive])]
  end

  @spec new_system_mail(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def new_system_mail(attrs) when is_map(attrs) do
    ensure_common_attrs(attrs)
    |> validate_system_mail_attrs()
  end

  @spec validate_system_mail_attrs(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def validate_system_mail_attrs(attrs) do
    %Mail{}
    |> Mail.system_mail_changeset(attrs)
    |> Ecto.Changeset.apply_action(:just_check)
  end

  defp ensure_common_attrs(attrs) do
    # ensure_key_exist(attrs, :create_time, Util.unixtime())
    attrs
    |> ensure_key_exist(:retention_time, @default_retention_time)
  end

  defp ensure_key_exist(attrs, key, value) do
    Enum.into(attrs, Map.put(%{}, key, value))
  end
end
