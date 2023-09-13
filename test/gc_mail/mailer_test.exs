defmodule GCMail.MailTest do
  use GCMail.DataCase
  import GCMail.MailFixtures
  alias GCMail.Mailer

  describe "deliver/1" do
    setup [:create_mailer]

    test "submit global mail with invalid mail", %{state: state} do
      {:noreply, state} = Mailer.handle_cast({:deliver, "invalid mail"}, state)
      assert [] == state.prepare_mails
    end

    test "submit global mail with valid mail", %{state: state} do
      mail = valid_global_system_mail()
      {:noreply, state} = Mailer.handle_cast({:deliver, mail}, state)
      assert [mail] == state.prepare_mails
    end
  end

  describe "handle_prepare_mails/1" do
    setup [:create_mailer]

    test "will do nothing if prepare_mails is empty", %{state: state} do
      loop_interval = 1
      state = put_in(state.loop_interval, loop_interval)
      assert 0 == length(state.prepare_mails)
      state = Mailer.handle_prepare_mails(state)
      assert 0 == length(state.prepare_mails)
    end

    test "will handle [#{Mailer.batch_num()}] items if prepare_mails has 1000 global system mail items",
         %{state: state} do
      total_num = 1000
      batch_num = Mailer.batch_num()

      state =
        Enum.to_list(1..total_num)
        |> Enum.reduce(state, fn _, acc ->
          {:noreply, acc} =
            Mailer.handle_cast({:deliver, valid_global_system_mail()}, acc)

          acc
        end)

      assert batch_num <= total_num
      assert total_num == length(state.prepare_mails)
      state = Mailer.handle_prepare_mails(state)
      assert batch_num == total_num - length(state.prepare_mails)
      assert 0 == length(state.prepare_emails)
    end

    test "will handle [#{Mailer.batch_num()}] items if prepare_mails has 1000 global personal mail items",
         %{state: state} do
      total_num = 1000
      batch_num = Mailer.batch_num()
      target_num = 2

      state =
        Enum.to_list(1..total_num)
        |> Enum.reduce(state, fn _, acc ->
          {:noreply, acc} =
            Mailer.handle_cast(
              {:deliver, valid_personal_system_mail(%{targets: valid_to(target_num)})},
              acc
            )

          acc
        end)

      assert total_num == length(state.prepare_mails)
      state = Mailer.handle_prepare_mails(state)
      assert batch_num == total_num - length(state.prepare_mails)
      assert batch_num * target_num == length(state.prepare_emails)
    end
  end

  describe "handle_prepare_emails/1" do
    setup [:create_mailer]

    test "will handle nothing if prepare_emails is empty", %{state: state} do
      loop_interval = 1
      state = put_in(state.loop_interval, loop_interval)
      assert 0 == length(state.prepare_emails)
      state = Mailer.handle_prepare_emails(state)
      assert 0 == length(state.prepare_emails)
    end

    test "will fetch emails from cache if prepare_emails not empty", %{state: state} do
      mail_id1 = System.unique_integer([:positive])
      mail_id2 = System.unique_integer([:positive])
      mail_ids = [mail_id1, mail_id2]
      targets = [1, 2]
      prepare_emails = make_prepare_emails(mail_ids, targets)

      state =
        %{state | prepare_emails: prepare_emails}
        |> Mailer.handle_prepare_emails()

      assert [] == state.prepare_emails

      fake_email_ids = make_fake_email_ids(mail_ids, targets)
      assert [] == fake_email_ids -- (GCMail.EmailCache.get_all(fake_email_ids) |> Map.keys())
    end
  end
end
