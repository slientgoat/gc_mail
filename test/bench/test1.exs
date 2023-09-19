Benchee.run(
  %{
    "deliver" => fn ->
      GCMail.SimpleHandler.deliver(
        GCMail.SimpleHandler.build_personal_system_mail(%{
          cfg_id: 1,
          targets: [System.unique_integer([:positive])]
        })
        |> elem(1)
      )
    end
  },
  parallel: 1,
  time: 60
)

Benchee.run(
  %{
    "deliver" => fn ->
      GCMail.SimpleHandler.deliver(
        GCMail.SimpleHandler.build_global_system_mail(%{
          cfg_id: 1
        })
        |> elem(1)
      )
    end
  },
  parallel: 1,
  time: 10
)

Benchee.run(
  %{
    "pull_global_ids" => fn ->
      GCMail.SimpleHandler.pull_global_ids(1, 1)
    end
  },
  parallel: 1,
  time: 5
)
