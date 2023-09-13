defmodule GCMail.Supervisor do
  use Supervisor

  def start_link(handler, opts) do
    Supervisor.start_link(__MODULE__, handler, [{:name, __MODULE__} | opts])
  end

  @impl true
  def init(handler) do
    children =
      [{GCMail.MailCache, []}, {GCMail.EmailCache, []}, {GCMail.Sup, [handler: handler]}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
