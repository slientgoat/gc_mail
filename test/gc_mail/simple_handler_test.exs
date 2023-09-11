defmodule GCMail.SimpleHandlerTest do
  use GCMail.DataCase
  import GCMail.MailFixtures
  alias GCMail.SimpleHandler

  describe "save_mails/1" do
    test "create global system mails" do
      {:ok, mails} =
        SimpleHandler.save_mails([
          valid_global_system_mail(),
          valid_global_system_mail()
        ])

      assert is_struct(List.first(mails), GCMail.Mail)
    end
  end

  describe "get_mail/1" do
    setup [:create_server]

    test "does not return the mail if the mail does not exist" do
      refute SimpleHandler.get_mail(1)
    end
  end

  describe "insert_to_cache/1" do
    setup [:create_server]

    test "will return ok when insert success" do
      {:ok, mails} =
        SimpleHandler.save_mails([
          valid_global_system_mail(),
          valid_global_system_mail()
        ])

      ids = Enum.map(mails, & &1.id)

      assert :ok == SimpleHandler.cache_mails(mails)
      assert mails == Enum.map(ids, &SimpleHandler.get_mail(&1))
    end
  end

  test "create role_mails with mail" do
  end
end
