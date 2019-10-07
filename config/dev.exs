use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :tmate, Tmate.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  cache_static_lookup: false,
  check_origin: false,
  secret_key_base: "rzC2wqnmk0VeKRZHiMtPDAkd5QeWdPSSX2H9pknPBgb4rdOA7TEqMq9Umm5bjFPs",
  host_url: "http://localhost:4000"

# Watch static and templates for browser reloading.
config :tmate, Tmate.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

config :tmate, :master,
  wsapi_key: "webhookkey"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :tmate, Tmate.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "tmate_dev",
  hostname: "postgres",
  pool_size: 10

config :tmate, :github_oauth,
  client_id: "36b15709e1e30f74ae42",
  client_secret: "88eda947d8e7f1a3b240ff805817da76f41d4ffa"

config :tmate, :redis,
  url: "redis://localhost:6379/0"

config :tmate, Tmate.Scheduler,
  enabled: true,
  jobs: [
    # Every minute
    {"* * * * *", {Tmate.SessionCleaner, :check_for_disconnected_sessions, []}},
    {"* * * * *", {Tmate.SessionCleaner, :prune_disconnected_sessions, []}},
  ]
