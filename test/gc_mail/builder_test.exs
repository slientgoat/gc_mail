defmodule GCMail.BuilderTest do
  alias GCMail.Type
  alias GCMail.Builder
  alias GCMail.Mail
  import GCMail.MailFixtures
  use GCMail.DataCase

  describe "validate_system_mail_attrs/1" do
    test "requires type,cfg_id" do
      assert {:error, changeset} = Builder.validate_system_mail_attrs(%{})

      assert %{cfg_id: ["can't be blank"], type: ["can't be blank"], send_at: ["can't be blank"]} ==
               errors_on(changeset)
    end

    test "validates maximum values assigns" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: valid_cfg_id(),
          assigns: List.duplicate("hh", 200)
        })

      assert %{assigns: ["should have at most 100 item(s)"]} = errors_on(changeset)
    end

    test "validates attaches with invalid elements" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: valid_cfg_id(),
          attaches: ["a"]
        })

      assert %{attaches: ["is invalid"]} = errors_on(changeset)
    end

    test "validates maximum values attaches" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: valid_cfg_id(),
          attaches: Enum.to_list(1..1000)
        })

      assert %{attaches: ["should have at most 100 item(s)"]} = errors_on(changeset)
    end

    test "validates attaches length must be even" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: valid_cfg_id(),
          attaches: [1]
        })

      assert %{attaches: ["expected length is even"]} = errors_on(changeset)
    end
  end

  describe "new_global_system_mail/1" do
    test "new global system mail with type,cfg_id" do
      cfg_id = valid_cfg_id()
      attaches = valid_attaches()

      {:ok, mail} =
        Builder.new_system_mail(%{
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
      cfg_id = valid_cfg_id()
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
      cfg_id = valid_cfg_id()
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
