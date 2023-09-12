defmodule GCMail.Sup do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true

  def init(opts) do
    children = GCMail.Mailer.start_args(opts)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
