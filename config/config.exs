import Config

config :gc_mail, GCMail.MailCache,
  model: :inclusive,
  levels: [
    # Default auto-generated L1 cache (local)
    {
      GCMail.MailCache.L1,
      # GC interval for pushing new generation: 24 hrs
      # Max 1 million entries in cache
      gc_interval: :timer.hours(24), max_size: 1_000_000
    },
    # Default auto-generated L2 cache (partitioned cache)
    {
      GCMail.MailCache.L2,
      primary: [
        # GC interval for pushing new generation: 48 hrs
        gc_interval: :timer.hours(48),
        # Max 1 million entries in cache
        max_size: 1_000_000
      ]
    }
  ]

config :gc_mail, GCMail.EmailCache,
  model: :inclusive,
  levels: [
    # Default auto-generated L1 cache (local)
    {
      GCMail.EmailCache.L1,
      gc_interval: :timer.hours(1), max_size: 1_000_000
    },
    {
      GCMail.EmailCache.L2,
      primary: [
        gc_interval: :timer.hours(2),
        max_size: 1_000_000
      ]
    }
  ]
