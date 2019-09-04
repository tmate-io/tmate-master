defmodule Tmate do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Tmate.Monitoring.setup()

    {:ok, monitoring_options} = Application.fetch_env(:tmate, Tmate.Monitoring.Endpoint)

    children = [
      # FIXME redis connection is not *necessary* to our application.
      # supervisor(Tmate.Redis, []),
      supervisor(Tmate.Endpoint, []),
      Plug.Cowboy.child_spec(scheme: :http, plug: Tmate.Monitoring.Endpoint, options: monitoring_options),
      worker(Tmate.Repo, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tmate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Tmate.Endpoint.config_change(changed, removed)
    :ok
  end
end
