defmodule GCMail.MailTest do
  alias GCMail.Type
  alias GCMail.Mail
  use GCMail.DataCase
  import GCMail.MailFixtures

  describe "validate_global_system_mail_attrs/1" do
    test "requires type,cfg_id" do
      assert {:error, changeset} = Mail.validate_global_system_mail_attrs(%{})

      assert %{cfg_id: ["can't be blank"], type: ["can't be blank"]} ==
               errors_on(changeset)
    end

    test "validates assigns with length over limit " do
      maximum = Mail.max_assigns_length()
      invalid_assigns = make_assigns(maximum * 2)

      {:error, changeset} =
        Mail.validate_global_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: 1,
          assigns: invalid_assigns
        })

      expert_tips = "should have at most #{maximum} item(s)"
      assert %{assigns: [expert_tips]} == errors_on(changeset)
    end

    test "validates attaches with invalid elements" do
      {:error, changeset} =
        Mail.validate_global_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: 1,
          attaches: ["a"]
        })

      assert %{attaches: ["is invalid"]} == errors_on(changeset)
    end

    test "validate attaches with length over limit" do
      maximum = Mail.max_attaches_length()
      invalid_attaches = Enum.to_list(1..(maximum * 2))

      {:error, changeset} =
        Mail.validate_global_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: 1,
          attaches: invalid_attaches
        })

      expert_tips = "should have at most #{maximum} item(s)"
      assert %{attaches: [expert_tips]} == errors_on(changeset)
    end

    test "vlidate attaches length must be even" do
      {:error, changeset} =
        Mail.validate_global_system_mail_attrs(%{
          type: Type.GlobalSystem,
          cfg_id: 1,
          attaches: [1]
        })

      assert %{attaches: ["expected length is even"]} = errors_on(changeset)
    end

    test ":targets,:title,:body will not be setup" do
      assert {:ok,
              %Mail{
                type: Type.GlobalSystem,
                from: "from",
                targets: nil,
                cfg_id: 1,
                title: nil,
                body: nil,
                assigns: %{"k1" => "v1"},
                attaches: [1, 2],
                send_at: 1,
                ttl: 1
              }} ==
               Mail.validate_global_system_mail_attrs(%{
                 type: Type.GlobalSystem,
                 from: "from",
                 targets: [1, 2],
                 cfg_id: 1,
                 title: "ignore",
                 body: "ignore",
                 assigns: %{"k1" => "v1"},
                 attaches: [1, 2],
                 send_at: 1,
                 ttl: 1
               })
    end

    test "return mail with the least valid attrs" do
      assert {:ok, ret} =
               Mail.validate_global_system_mail_attrs(%{
                 type: Type.GlobalSystem,
                 cfg_id: 1
               })

      assert ret.send_at > 0
      assert ret.ttl == Mail.default_ttl()
    end
  end
end
