# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :tmate,
  ecto_repos: [Tmate.Repo]

# Configures the endpoint
config :tmate, TmateWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DKaayGHtzQJFsdBK4HfamYXCdSd4aOLV7T5+XY+9XzIKuoUWYwMhJH+/U2N/7zkf",
  render_errors: [view: TmateWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Tmate.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason


config :tmate, Tmate.Monitoring.Endpoint,
  enabled: true,
  cowboy_opts: [port: 9100]

config :tmate, Tmate.MonitoringCollector,
  metrics_enabled: true

config :prometheus, Tmate.PlugExporter,
  path: "/metrics",
  format: :auto,
  registry: :default,
  auth: false

config :tmate, Tmate.Mailer,
  from: System.get_env("EMAIL_FROM", "tmate <support@tmate.io>")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
