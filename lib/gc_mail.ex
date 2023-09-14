defmodule GCMail do
  @moduledoc """
  Documentation for `GCMail`.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour GCMail.Behaviour
      alias GCMail.Mail
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

      def cast_email_id(email) do
        email
      end

      defdelegate build_global_system_mail(attrs), to: Mail
      defdelegate build_personal_system_mail(attrs), to: Mail
      defdelegate build_global_custom_mail(attrs), to: Mail
      defdelegate build_personal_custom_mail(attrs), to: Mail
      defdelegate deliver(mail), to: Mailer
      defoverridable cast_email_id: 1
    end
  end
end
