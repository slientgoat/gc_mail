defmodule GCMail do
  @moduledoc """
  Documentation for `GCMail`.
  """

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

  alias GCMail.Builder

  def build(Type.GlobalSystem = type, attrs) do
    attrs
    |> Enum.into(%{type: type})
    |> Builder.new_system_mail()
  end
end
