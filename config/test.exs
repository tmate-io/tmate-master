use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tmate, Tmate.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: if System.get_env("DEBUG"), do: :debug, else: :warn

# Set a higher stacktrace during test
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :tmate, Tmate.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "tmate_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
