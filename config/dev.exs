use Mix.Config

# Configure your database
config :tmate, Tmate.Repo,
  # username: "postgres",
  # password: "postgres",
  database: "tmate_dev",
  hostname: "postgres",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :tmate, TmateWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :tmate, TmateWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/tmate_web/{live,views}/.*(ex)$",
      ~r"lib/tmate_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :tmate, :master,
  internal_api: [auth_token: "internal_api_auth_token"]

config :tmate, Tmate.Scheduler,
  enabled: true,
  jobs: [
    # Every 5 minutes
    {"*/5 * * * *", {Tmate.SessionCleaner, :check_for_disconnected_sessions, []}},
    {"*/5 * * * *", {Tmate.SessionCleaner, :prune_sessions, []}},
  ]
