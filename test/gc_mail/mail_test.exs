defmodule GCMail.MailTest do
  alias GCMail.Mail.Type
  alias GCMail.Mail
  use GCMail.DataCase
  import GCMail.MailFixtures

  describe "validate_assigns/1" do
    test "invalid subset " do
      {:error, changeset} = Mail.validate(&Mail.validate_assigns/1, %{assigns: %{"k1" => 1}})
      expert_tips = "is invalid"
      assert %{assigns: [expert_tips]} == errors_on(changeset)
    end

    test "length over limit " do
      maximum = Mail.max_assigns_length()
      invalid_assigns = make_assigns(maximum * 2)

      {:error, changeset} = Mail.validate(&Mail.validate_assigns/1, %{assigns: invalid_assigns})
      expert_tips = "should have at most #{maximum} item(s)"
      assert %{assigns: [expert_tips]} == errors_on(changeset)
    end
  end

  describe "validate_attaches/1" do
    test "invalid subset" do
      {:error, changeset} = Mail.validate(&Mail.validate_assigns/1, %{attaches: ["a"]})
      assert %{attaches: ["is invalid"]} == errors_on(changeset)
    end

    test "length over limit" do
      maximum = Mail.max_attaches_length()
      invalid_attaches = Enum.to_list(1..(maximum * 2))

      {:error, changeset} =
        Mail.validate(&Mail.validate_attaches/1, %{attaches: invalid_attaches})

      expert_tips = "should have at most #{maximum} item(s)"
      assert %{attaches: [expert_tips]} == errors_on(changeset)
    end

    test "length must be even" do
      {:error, changeset} = Mail.validate(&Mail.validate_attaches/1, %{attaches: [1]})
      assert %{attaches: ["expected length is even"]} = errors_on(changeset)
    end
  end

  test "validate_targets for length over limit " do
    maximum = Mail.max_targets_length()
    temp = Enum.to_list(1..(maximum * 2))

    {:error, changeset} = Mail.validate(&Mail.validate_targets/1, %{targets: temp})
    expert_tips = "should have at most #{maximum} item(s)"
    assert %{targets: [expert_tips]} == errors_on(changeset)
  end

  test "validate_title for length over limit " do
    maximum = Mail.max_title_length()
    temp = List.duplicate("a", maximum * 2) |> Enum.join("")

    {:error, changeset} = Mail.validate(&Mail.validate_title/1, %{title: temp})
    expert_tips = "should be at most #{maximum} character(s)"
    assert %{title: [expert_tips]} == errors_on(changeset)
  end

  test "validate_body for length over limit " do
    maximum = Mail.max_body_length()
    temp = List.duplicate("a", maximum * 2) |> Enum.join("")

    {:error, changeset} = Mail.validate(&Mail.validate_body/1, %{body: temp})
    expert_tips = "should be at most #{maximum} character(s)"
    assert %{body: [expert_tips]} == errors_on(changeset)
  end

  describe "build_global_system_mail/1" do
    test "requires cfg_id" do
      assert {:error, changeset} = Mail.build_global_system_mail(%{})

      assert %{cfg_id: ["can't be blank"]} == errors_on(changeset)
    end

    test ":targets,:title,:body,:type will not be setup" do
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
               Mail.build_global_system_mail(%{
                 type: "type",
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
      type = Type.GlobalSystem

      assert {:ok, %Mail{type: ^type, cfg_id: 1} = ret} =
               Mail.build_global_system_mail(%{
                 type: type,
                 cfg_id: 1
               })

      assert ret.send_at > 0
      assert ret.ttl == Mail.default_ttl()
    end
  end

  describe "build_personal_system_mail/1" do
    test "requires cfg_id" do
      assert {:error, changeset} = Mail.build_personal_system_mail(%{})

      assert %{cfg_id: ["can't be blank"], targets: ["can't be blank"]} == errors_on(changeset)
    end

    test ":title,:body will not be setup" do
      assert {:ok,
              %Mail{
                type: Type.PersonalSystem,
                from: "from",
                targets: [1, 2],
                cfg_id: 1,
                title: nil,
                body: nil,
                assigns: %{"k1" => "v1"},
                attaches: [1, 2],
                send_at: 1,
                ttl: 1
              }} ==
               Mail.build_personal_system_mail(%{
                 type: "type",
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
      type = Type.PersonalSystem

      assert {:ok, %Mail{type: ^type, cfg_id: 1, targets: [1, 2]} = ret} =
               Mail.build_personal_system_mail(%{
                 type: type,
                 cfg_id: 1,
                 targets: [1, 2]
               })

      assert ret.send_at > 0
      assert ret.ttl == Mail.default_ttl()
    end
  end

  describe "build_global_custom_mail/1" do
    test "requires title,body" do
      assert {:error, changeset} = Mail.build_global_custom_mail(%{})

      assert %{title: ["can't be blank"], body: ["can't be blank"]} == errors_on(changeset)
    end

    test ":cfg_id,:targets,:type will not be setup" do
      assert {:ok,
              %Mail{
                type: Type.GlobalCustom,
                from: "from",
                targets: nil,
                cfg_id: nil,
                title: "title",
                body: "body",
                assigns: %{"k1" => "v1"},
                attaches: [1, 2],
                send_at: 1,
                ttl: 1
              }} ==
               Mail.build_global_custom_mail(%{
                 type: "type",
                 from: "from",
                 targets: "ignore",
                 cfg_id: "ignore",
                 title: "title",
                 body: "body",
                 assigns: %{"k1" => "v1"},
                 attaches: [1, 2],
                 send_at: 1,
                 ttl: 1
               })
    end

    test "return mail with the least valid attrs" do
      type = Type.GlobalCustom

      assert {:ok, %Mail{type: ^type, title: "title", body: "body"} = ret} =
               Mail.build_global_custom_mail(%{
                 type: type,
                 title: "title",
                 body: "body"
               })

      assert ret.send_at > 0
      assert ret.ttl == Mail.default_ttl()
    end
  end

  describe "build_personal_custom_mail/1" do
    test "requires title,body,targets" do
      assert {:error, changeset} = Mail.build_personal_custom_mail(%{})

      assert %{
               title: ["can't be blank"],
               body: ["can't be blank"],
               targets: ["can't be blank"]
             } ==
               errors_on(changeset)
    end

    test ":cfg_id,:type will not be setup" do
      assert {:ok,
              %Mail{
                type: Type.PersonalCustom,
                from: "from",
                targets: [1, 2],
                cfg_id: nil,
                title: "title",
                body: "body",
                assigns: %{"k1" => "v1"},
                attaches: [1, 2],
                send_at: 1,
                ttl: 1
              }} ==
               Mail.build_personal_custom_mail(%{
                 type: "type",
                 from: "from",
                 targets: [1, 2],
                 cfg_id: "ignore",
                 title: "title",
                 body: "body",
                 assigns: %{"k1" => "v1"},
                 attaches: [1, 2],
                 send_at: 1,
                 ttl: 1
               })
    end

    test "return mail with the least valid attrs" do
      type = Type.PersonalCustom

      assert {:ok, %Mail{title: "title", body: "body", targets: [1, 2], type: ^type} = ret} =
               Mail.build_personal_custom_mail(%{
                 type: type,
                 title: "title",
                 body: "body",
                 targets: [1, 2]
               })

      assert ret.send_at > 0
      assert ret.ttl == Mail.default_ttl()
    end
  end
end
