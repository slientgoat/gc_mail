defmodule GCMail.EmailCache do
  use Nebulex.Cache,
    otp_app: :gc_mail,
    adapter: Nebulex.Adapters.Multilevel

  ## Cache Levels

  # Default auto-generated L1 cache (local)
  defmodule L1 do
    use Nebulex.Cache,
      otp_app: :gc_mail,
      adapter: Nebulex.Adapters.Local
  end

  # Default auto-generated L2 cache (partitioned cache)
  defmodule L2 do
    use Nebulex.Cache,
      otp_app: :gc_mail,
      adapter: Nebulex.Adapters.Partitioned
  end

  ## TODO: Add, remove or modify the auto-generated cache levels above
end
