defmodule GCMail.Enums do
  use EnumType

  defenum MailType do
    value(PersonalSystem, 1)
    value(PersonalCustom, 2)
    value(GlobalSystem, 3)
    value(GlobalCustom, 4)
    default(PersonalCustom)

    def personal, do: [PersonalSystem, PersonalCustom]
    def global, do: [GlobalSystem, GlobalCustom]
  end
end
