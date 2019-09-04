# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :tmate, Tmate.Endpoint,
  url: [host: "localhost"],
  root: ".",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Tmate.PubSub,
           adapter: Phoenix.PubSub.PG2],
  instrumenters: [Tmate.Endpoint.PhoenixInstrumenter]

config :tmate, ecto_repos: [Tmate.Repo]

config :tmate, Tmate.Monitoring.Endpoint,
  port: 4100
config :prometheus, Tmate.PlugExporter,
  path: "/metrics",
  format: :auto,
  registry: :default,
  auth: false


config :logger,
  backends: [:console]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:remote_ip]

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :phoenix, :json_library, Jason

config :tmate, :redis,
  pool_size: 2,
  pool_max_overflow: 2

import_config "#{Mix.env}.exs"
