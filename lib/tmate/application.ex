defmodule Tmate.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Tmate.Monitoring.setup()

    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Tmate.Repo,
      # Start the endpoint when the application starts
      TmateWeb.Endpoint
      # Starts a worker by calling: Tmate.Worker.start_link(arg)
      # {Tmate.Worker, arg},
    ]

    {:ok, monitoring_options} = Application.fetch_env(:tmate, Tmate.Monitoring.Endpoint)
    {:ok, scheduler_options} = Application.fetch_env(:tmate, Tmate.Scheduler)

    children = cond do
      monitoring_options[:enabled] -> children ++ [
        Plug.Cowboy.child_spec(scheme: :http, plug: Tmate.Monitoring.Endpoint,
                               options: monitoring_options[:cowboy_opts])
      ]
      true -> children
    end

    children = cond do
      scheduler_options[:enabled] -> children ++ [Tmate.Scheduler]
      true -> children
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tmate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TmateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
