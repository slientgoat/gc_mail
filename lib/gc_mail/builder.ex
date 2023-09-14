defmodule GCMail.Builder do
  alias GCMail.Mail
  alias GCMail.Mail.Type
  alias GCMail.Email

  @spec build_global_system_mail(map) :: {:error, Ecto.Changeset.t()} | {:ok, %Mail{}}
  def build_global_system_mail(attrs) when is_map(attrs) do
    attrs
    |> Map.put(:type, Type.GlobalSystem)
    |> Mail.validate_global_system_mail_attrs()
  end

  @spec build_personal_system_mail(map) :: {:error, Ecto.Changeset.t()} | {:ok, %Mail{}}
  def build_personal_system_mail(attrs) when is_map(attrs) do
    attrs
    |> Map.put(:type, Type.PersonalSystem)
    |> Mail.validate_personal_system_mail_attrs()
  end

  @spec build_global_custom_mail(map) :: {:error, Ecto.Changeset.t()} | {:ok, %Mail{}}
  def build_global_custom_mail(attrs) when is_map(attrs) do
    attrs
    |> Map.put(:type, Type.GlobalCustom)
    |> Mail.validate_global_custom_mail_attrs()
  end

  @spec build_personal_custom_mail(map) :: {:error, Ecto.Changeset.t()} | {:ok, %Mail{}}
  def build_personal_custom_mail(attrs) when is_map(attrs) do
    attrs
    |> Map.put(:type, Type.PersonalCustom)
    |> Mail.validate_personal_system_mail_attrs()
  end

  @spec build_email(map) :: %Email{}
  def build_email(attrs) when is_map(attrs) do
    %Email{}
    |> Map.merge(attrs)
  end
end
