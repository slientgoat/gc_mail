import Config

config :gc_mail, GCMail.Cache,
  model: :inclusive,
  levels: [
    # Default auto-generated L1 cache (local)
    {
      GCMail.Cache.L1,
      # GC interval for pushing new generation: 12 hrs
      # Max 1 million entries in cache
      gc_interval: :timer.hours(72), max_size: 1_000_000
    },
    # Default auto-generated L2 cache (partitioned cache)
    {
      GCMail.Cache.L2,
      primary: [
        # GC interval for pushing new generation: 12 hrs
        gc_interval: :timer.hours(24),
        # Max 1 million entries in cache
        max_size: 1_000_000
      ]
    }
  ]
