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
end
