defmodule GCMail.BuilderTest do
  alias GCMail.Type
  alias GCMail.Builder
  alias GCMail.Mail
  import GCMail.MailFixtures
  use GCMail.DataCase

  describe "new_global_system_mail/1" do
    test "new global system mail with type,cfg_id" do
      cfg_id = 1
      attaches = valid_attaches()

      {:ok, mail} =
        Builder.new_global_system_mail(%{
          type: Type.GlobalSystem,
          cfg_id: cfg_id,
          attaches: attaches
        })

      assert %Mail{
               type: Type.GlobalSystem,
               cfg_id: cfg_id,
               title: nil,
               body: nil,
               assigns: nil,
               attaches: attaches,
               send_at: mail.send_at,
               trigger_at: nil,
               ttl: Builder.default_ttl()
             } == mail
    end

    test "new global system mail that title, body will be ignore" do
      cfg_id = 1
      attaches = valid_attaches()

      {:ok, mail} =
        Builder.new_system_mail(%{
          type: Type.GlobalSystem,
          cfg_id: cfg_id,
          attaches: attaches,
          title: "will be ignore",
          body: "will be ignore"
        })

      assert %Mail{
               type: Type.GlobalSystem,
               cfg_id: cfg_id,
               title: nil,
               body: nil,
               assigns: nil,
               attaches: attaches,
               send_at: mail.send_at,
               trigger_at: nil,
               ttl: Builder.default_ttl()
             } == mail
    end

    test "new global system mail with trigger_at and ttl" do
      cfg_id = 1
      attaches = valid_attaches()

      {:ok, mail} =
        Builder.new_system_mail(%{
          type: Type.GlobalSystem,
          cfg_id: cfg_id,
          attaches: attaches,
          trigger_at: 1,
          ttl: 1
        })

      assert %Mail{
               type: Type.GlobalSystem,
               cfg_id: cfg_id,
               title: nil,
               body: nil,
               assigns: nil,
               send_at: mail.send_at,
               attaches: attaches,
               trigger_at: 1,
               ttl: 1
             } == mail
    end
  end
end
