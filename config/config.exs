# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :tmate, Tmate.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "rzC2wqnmk0VeKRZHiMtPDAkd5QeWdPSSX2H9pknPBgb4rdOA7TEqMq9Umm5bjFPs",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Tmate.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :logger,
  backends: [:console, Rollbax.Notifier]

config :logger, Rollbax.Notifier,
  level: :error

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :redis, Tmate,
  url: "redis://localhost:6379/0",
  pool_size: 2,
  pool_max_overflow: 2

config :tmate, :ssh,
  host: "localhost",
  port: 2200

config :tmate, :rollbar,
  token: "ac9fa1686f8549d89fc092ad081f3128"

config :rollbax,
  access_token: "cbf96daf284c4c85b608e86aa3def4c0",
  environment: Mix.env
