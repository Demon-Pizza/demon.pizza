defmodule DemonPizza.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DemonPizzaWeb.Telemetry,
      DemonPizza.Repo,
      {DNSCluster, query: Application.get_env(:demon_pizza, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DemonPizza.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DemonPizza.Finch},
      # Start a worker by calling: DemonPizza.Worker.start_link(arg)
      # {DemonPizza.Worker, arg},
      # Start to serve requests, typically the last entry
      DemonPizzaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DemonPizza.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DemonPizzaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
