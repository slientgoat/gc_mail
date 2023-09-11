defmodule GCMail.ServerTest do
  use GCMail.DataCase
  import GCMail.MailFixtures
  alias GCMail.Server

  describe "submit_mail/1" do
    setup [:create_server]

    test "submit global mail with invalid mail", %{state: state} do
      {:noreply, state} = Server.handle_cast({:submit_mail, "invalid mail"}, state)

      assert [] == state.prepare_mails
    end

    test "submit global mail with valid mail", %{state: state} do
      mail = valid_global_system_mail()
      {:noreply, state} = Server.handle_cast({:submit_mail, mail}, state)
      assert [mail] == state.prepare_mails
    end
  end

  describe "handle_info(:loop,state)" do
    setup [:create_server]

    test "will do nothing if prepare_mails is empty in once loop", %{state: state} do
      loop_interval = 1
      state = put_in(state.loop_interval, loop_interval)
      assert 0 == length(state.prepare_mails)
      {:noreply, state} = Server.handle_info(:loop_handle_prepare_mails, state)
      assert_receive(:loop_handle_prepare_mails, 10)
      assert 0 == length(state.prepare_mails)
    end

    test "will handle 200 items if prepare_mails has 1000 global system mail items in once loop",
         %{state: state} do
      loop_interval = 1
      state = put_in(state.loop_interval, loop_interval)

      state =
        Enum.to_list(1..1000)
        |> Enum.reduce(state, fn _, acc ->
          {:noreply, acc} =
            Server.handle_cast({:submit_mail, valid_global_system_mail()}, acc)

          acc
        end)

      assert 1000 == length(state.prepare_mails)
      {:noreply, state} = Server.handle_info(:loop_handle_prepare_mails, state)
      assert_receive(:loop_handle_prepare_mails, 10)
      assert 800 == length(state.prepare_mails)
      assert 0 == length(state.personal_mail_ids)
    end

    test "will handle 200 items if prepare_mails has 1000 global personal mail items in once loop",
         %{state: state} do
      loop_interval = 1
      state = put_in(state.loop_interval, loop_interval)

      state =
        Enum.to_list(1..1000)
        |> Enum.reduce(state, fn _, acc ->
          {:noreply, acc} =
            Server.handle_cast(
              {:submit_mail, valid_personal_system_mail(%{to: valid_to(2)})},
              acc
            )

          acc
        end)

      assert 1000 == length(state.prepare_mails)

      {:noreply, state} =
        Server.handle_info(:loop_handle_prepare_mails, state)

      assert_receive(:loop_handle_prepare_mails, 10)
      assert 800 == length(state.prepare_mails)
      assert 400 == length(state.personal_mail_ids)
    end
  end
end
