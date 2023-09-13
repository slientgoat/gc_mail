defmodule GCMail do
  @moduledoc """
  Documentation for `GCMail`.
  """

  use EnumType
  alias GCMail.Builder

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

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour GCMail.Behaviour
      alias GCMail.Mailer

      @opts opts

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        GCMail.Supervisor.start_link(__MODULE__, opts)
      end

      def build_global_system(attrs) do
        attrs
        |> Enum.into(%{type: Type.GlobalSystem})
        |> Builder.new_system_mail()
      end

      def build_personal_system(attrs) do
        attrs
        |> Enum.into(%{type: Type.PersonalSystem})
        |> Builder.new_system_mail()
      end

      def cast_email_id(email) do
        email
      end

      defdelegate deliver(mail), to: Mailer
      defoverridable cast_email_id: 1
    end
  end
end
