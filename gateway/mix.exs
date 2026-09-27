defmodule LontarGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :lontar_gateway,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl, :crypto],
      mod: {LontarGateway.Application, []}
    ]
  end
end
