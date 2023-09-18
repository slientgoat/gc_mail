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

      def load_mails() do
        []
      end

      def load_emails() do
        []
      end

      defdelegate build_global_system_mail(attrs), to: Mail
      defdelegate build_personal_system_mail(attrs), to: Mail
      defdelegate build_global_custom_mail(attrs), to: Mail
      defdelegate build_personal_custom_mail(attrs), to: Mail
      defdelegate deliver(mail), to: Mailer
      defoverridable cast_email_id: 1, load_mails: 0, load_emails: 0
    end
  end

  def t1(num) do
    try do
      do_something_that_may_fail(num)
    rescue
      ArgumentError ->
        IO.puts("Invalid argument given")
    catch
      value ->
        IO.puts("Caught #{inspect(value)}")
    after
      IO.puts("This is printed regardless if it failed or succeeded")
    end
  end

  def do_something_that_may_fail(1) do
    raise "must more than 1"
  end

  def do_something_that_may_fail(2) do
    throw("must more than 2")
  end

  def do_something_that_may_fail(num) do
    2 / num
  end
end
