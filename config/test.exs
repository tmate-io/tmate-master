use Mix.Config

# Configure your database
config :tmate, Tmate.Repo,
  username: "postgres",
  password: "postgres",
  database: "tmate_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tmate, TmateWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: if System.get_env("DEBUG"), do: :debug, else: :warn

config :phoenix, :stacktrace_depth, 20

config :tmate, Tmate.Monitoring.Endpoint,
  enabled: false

config :tmate, :master,
  internal_api: [auth_token: "internal_api_auth_token"]

config :tmate, Tmate.Scheduler,
  enabled: false

config :tmate, Tmate.Mailer,
  adapter: Bamboo.TestAdapter
