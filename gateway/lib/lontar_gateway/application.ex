defmodule LontarGateway.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    :inets.start()
    :ssl.start()
    :persistent_term.put({LontarGateway.Config, :config}, LontarGateway.Config.load())
    LontarGateway.RateLimit.init()

    children = [LontarGateway.Server]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: LontarGateway.Supervisor
    )
  end
end
