defmodule GCMail do
  @moduledoc """
  Documentation for `GCMail`.
  """
  alias GCMail.Mail.Type
  import Ex2ms

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
      defdelegate pull_global_ids_after_unixtime(unixtime), to: GCMail
      defdelegate pull_global_ids_after_id(id), to: GCMail
      defdelegate pull_personal_ids(last_personal_id, to), to: GCMail
      defdelegate get_mail(mail_id), to: GCMail.MailCache, as: :get
      defoverridable load_mails: 0, load_emails: 0
    end
  end

  def pull_global_ids_after_unixtime(unixtime) when is_integer(unixtime) do
    make_global_ids_match_after_unixtime(unixtime)
    |> GCMail.MailCache.all()
    |> Enum.uniq()
  end

  defp make_global_ids_match_after_unixtime(unixtime) do
    fun do
      {_, key, %{type: type, send_at: send_at}, _, _}
      when (type == Type.GlobalSystem or type == Type.GlobalCustom) and send_at > ^unixtime ->
        key
    end
  end

  def pull_global_ids_after_id(id) when is_integer(id) do
    make_global_ids_match_after_id(id)
    |> GCMail.MailCache.all()
    |> Enum.uniq()
  end

  defp make_global_ids_match_after_id(id) when is_integer(id) do
    fun do
      {_, key, %{type: type, send_at: send_at}, _, _}
      when (type == Type.GlobalSystem or type == Type.GlobalCustom) and key > ^id ->
        key
    end
  end

  def pull_personal_ids(last_personal_id, to) do
    personal_ids_match_spec(last_personal_id, to)
    |> GCMail.EmailCache.all()
    |> Enum.uniq()
  end

  defp personal_ids_match_spec(nil, target) do
    fun do
      {_, _key, %{to: to, mail_id: mail_id}, _, _} when to == ^target ->
        mail_id
    end
  end

  defp personal_ids_match_spec(last_personal_id, target) do
    fun do
      {_, _, %{to: to, mail_id: mail_id}, _, _}
      when to == ^target and mail_id > ^last_personal_id ->
        mail_id
    end
  end
end
