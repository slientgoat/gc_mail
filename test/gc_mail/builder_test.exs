defmodule GCMail.BuilderTest do
  alias GCMail.Enums.MailType
  alias GCMail.Builder
  alias GCMail.Mail
  import GCMail.MailFixtures
  use GCMail.DataCase

  describe "validate_system_mail_attrs/1" do
    test "requires mail_type,cfg_id" do
      assert {:error, changeset} = Builder.validate_system_mail_attrs(%{})
      assert %{cfg_id: ["can't be blank"], mail_type: ["can't be blank"]} == errors_on(changeset)
    end

    test "validates maximum values args" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          mail_type: MailType.GlobalSystem,
          cfg_id: valid_cfg_id(),
          args: List.duplicate("hh", 200)
        })

      assert %{args: ["should have at most 100 item(s)"]} = errors_on(changeset)
    end

    test "validates attaches with invalid elements" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          mail_type: MailType.GlobalSystem,
          cfg_id: valid_cfg_id(),
          attaches: ["a"]
        })

      assert %{attaches: ["is invalid"]} = errors_on(changeset)
    end

    test "validates maximum values attaches" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          mail_type: MailType.GlobalSystem,
          cfg_id: valid_cfg_id(),
          attaches: Enum.to_list(1..1000)
        })

      assert %{attaches: ["should have at most 100 item(s)"]} = errors_on(changeset)
    end

    test "validates attaches length must be even" do
      {:error, changeset} =
        Builder.validate_system_mail_attrs(%{
          mail_type: MailType.GlobalSystem,
          cfg_id: valid_cfg_id(),
          attaches: [1]
        })

      assert %{attaches: ["expected length is even"]} = errors_on(changeset)
    end
  end

  describe "new_global_system_mail/1" do
    test "new global system mail with mail_type,cfg_id" do
      cfg_id = valid_cfg_id()
      attaches = valid_attaches()

      {:ok, mail} =
        Builder.new_system_mail(%{
          mail_type: MailType.GlobalSystem,
          cfg_id: cfg_id,
          attaches: attaches
        })

      assert %Mail{
               mail_type: MailType.GlobalSystem,
               cfg_id: cfg_id,
               title: nil,
               body: nil,
               args: nil,
               attaches: attaches,
               create_time: mail.create_time,
               trigger_time: nil,
               retention_time: Builder.default_retention_time()
             } == mail
    end

    test "new global system mail that title, body will be ignore" do
      cfg_id = valid_cfg_id()
      attaches = valid_attaches()

      {:ok, mail} =
        Builder.new_system_mail(%{
          mail_type: MailType.GlobalSystem,
          cfg_id: cfg_id,
          attaches: attaches,
          title: "will be ignore",
          body: "will be ignore"
        })

      assert %Mail{
               mail_type: MailType.GlobalSystem,
               cfg_id: cfg_id,
               title: nil,
               body: nil,
               args: nil,
               attaches: attaches,
               create_time: mail.create_time,
               trigger_time: nil,
               retention_time: Builder.default_retention_time()
             } == mail
    end

    test "new global system mail with trigger_time and retention_time" do
      cfg_id = valid_cfg_id()
      attaches = valid_attaches()

      {:ok, mail} =
        Builder.new_system_mail(%{
          mail_type: MailType.GlobalSystem,
          cfg_id: cfg_id,
          attaches: attaches,
          trigger_time: 1,
          retention_time: 1
        })

      assert %Mail{
               mail_type: MailType.GlobalSystem,
               cfg_id: cfg_id,
               title: nil,
               body: nil,
               args: nil,
               create_time: mail.create_time,
               attaches: attaches,
               trigger_time: 1,
               retention_time: 1
             } == mail
    end
  end
end
