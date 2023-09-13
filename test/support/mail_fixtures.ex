defmodule GCMail.MailFixtures do
  alias GCMail.Type
  alias GCMail.Builder
  alias GCMail.Mailer

  def valid_global_system_mail(attrs \\ %{}) do
    {:ok, mail} =
      attrs
      |> Enum.into(%{cfg_id: valid_cfg_id(), type: Type.GlobalSystem})
      |> Builder.new_system_mail()

    mail
  end

  def valid_personal_system_mail(attrs \\ %{}) do
    {:ok, mail} =
      attrs
      |> Enum.into(%{cfg_id: valid_cfg_id(), type: Type.PersonalSystem})
      |> Builder.new_system_mail()

    mail
  end

  def valid_cfg_id() do
    Builder.cfg_ids() |> Enum.random()
  end

  def valid_attaches() do
    [1, 1]
  end

  def valid_to(num) do
    Enum.to_list(1..num) |> Enum.map(fn _x -> System.unique_integer([:positive]) end)
  end

  def create_mailer(_args \\ []) do
    opts = [id: 1, handler: GCMail.SimpleHandler]
    {:ok, state, {:continue, continue}} = Mailer.init(opts)
    {:noreply, state} = Mailer.handle_continue(continue, state)
    %{state: state}
  end

  def new_mail(opts \\ []) do
    Enum.reduce(opts, %GCMail.Mail{}, &do_new/2)
  end

  defp do_new({key, value}, mail) when key in [:id, :targets] do
    Map.put(mail, key, value)
  end

  defp do_new({key, value}, _mail) do
    raise ArgumentError,
      message: """
      invalid field `#{inspect(key)}` (value=#{inspect(value)}) for GCMail.Builder.new/1.
      """
  end

  def make_prepare_emails(mail_ids, targets) do
    Enum.map(mail_ids, &new_mail(id: &1, targets: targets))
    |> GCMail.Mailer.make_prepare_emails()
  end

  def make_fake_email_ids(mail_ids, targets) do
    for mail_id <- mail_ids, to <- targets, do: fake_email_id(mail_id, to)
  end

  def fake_email_id(mail_id, to) do
    "#{to}|#{mail_id}"
  end
end
