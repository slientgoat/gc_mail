Benchee.run(
  %{
    "deliver" => fn ->
      GCMail.SimpleHandler.deliver(
        GCMail.SimpleHandler.build_personal_system(%{
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
