defmodule GCMail.Builder do
  alias GCMail.Mail
  alias GCMail.Email

  @spec new_global_system_mail(map) :: {:error, Ecto.Changeset.t()} | {:ok, map}
  def new_global_system_mail(attrs) when is_map(attrs) do
    attrs
    |> Map.put(:type, GCMail.Type.GlobalSystem)
    |> Mail.validate_global_system_mail_attrs()
  end

  @spec new_email(map) :: %Email{}
  def new_email(attrs) when is_map(attrs) do
    %Email{}
    |> Map.merge(attrs)
  end
end
