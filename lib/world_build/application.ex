defmodule WorldBuild.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WorldBuildWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:world_build, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WorldBuild.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: WorldBuild.Finch},
      # Start a worker by calling: WorldBuild.Worker.start_link(arg)
      # {WorldBuild.Worker, arg},
      # Start to serve requests, typically the last entry
      WorldBuildWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WorldBuild.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WorldBuildWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
