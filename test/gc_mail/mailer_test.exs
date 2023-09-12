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

  describe "handle_info(:loop,state)" do
    setup [:create_mailer]

    test "will do nothing if prepare_mails is empty in once loop", %{state: state} do
      loop_interval = 1
      state = put_in(state.loop_interval, loop_interval)
      assert 0 == length(state.prepare_mails)
      {:noreply, state} = Mailer.handle_info(:loop_handle_prepare_mails, state)
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
            Mailer.handle_cast({:deliver, valid_global_system_mail()}, acc)

          acc
        end)

      assert 1000 == length(state.prepare_mails)
      {:noreply, state} = Mailer.handle_info(:loop_handle_prepare_mails, state)
      assert_receive(:loop_handle_prepare_mails, 10)
      assert 800 == length(state.prepare_mails)
      assert 0 == length(state.prepare_emails)
    end

    test "will handle 200 items if prepare_mails has 1000 global personal mail items in once loop",
         %{state: state} do
      loop_interval = 1
      state = put_in(state.loop_interval, loop_interval)

      state =
        Enum.to_list(1..1000)
        |> Enum.reduce(state, fn _, acc ->
          {:noreply, acc} =
            Mailer.handle_cast(
              {:deliver, valid_personal_system_mail(%{targets: valid_to(2)})},
              acc
            )

          acc
        end)

      assert 1000 == length(state.prepare_mails)

      {:noreply, state} =
        Mailer.handle_info(:loop_handle_prepare_mails, state)

      assert_receive(:loop_handle_prepare_mails, 10)
      assert 800 == length(state.prepare_mails)
      assert 400 == length(state.prepare_emails)
    end
  end

  describe "cache_mails/1" do
    ids = [System.unique_integer([:positive]), System.unique_integer([:positive])]
    mails = Enum.map(ids, &new_mail(id: &1))
    Mailer.cache_mails(mails)
    assert mails == GCMail.MailCache.get_all(ids) |> Map.values()
  end

  describe "cache_emails/1" do
    mail_id1 = System.unique_integer([:positive])
    mail_id2 = System.unique_integer([:positive])
    mail_ids = [mail_id1, mail_id2]
    targets = [1, 2]

    emails =
      Enum.map(mail_ids, &new_mail(id: &1, targets: targets))
      |> Mailer.make_prepare_emails()

    Mailer.cache_emails(emails)
    keys = for mail_id <- mail_ids, to <- targets, do: "#{to}|#{mail_id}"
    expert = [{1, mail_id1}, {1, mail_id2}, {2, mail_id1}, {2, mail_id2}]
    assert expert == GCMail.EmailCache.get_all(keys) |> Map.values()
  end
end
