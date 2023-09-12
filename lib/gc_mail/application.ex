defmodule GCMail.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :dev do
        [
          {GCMail.MailCache, []},
          {GCMail.EmailCache, []},
          {GCMail.Sup, handler: GCMail.SimpleHandler}
        ]
      else
        [
          {GCMail.MailCache, []},
          {GCMail.EmailCache, []}
        ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tmp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
