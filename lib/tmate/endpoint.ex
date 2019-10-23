defmodule Tmate.Endpoint do
  use Phoenix.Endpoint, otp_app: :tmate

  socket "/socket", Tmate.UserSocket,
    websocket: []

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :tmate, gzip: false,
    only: ~w(css img js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Tmate.Util.PlugRemoteIp
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "tmate_session",
    signing_salt: "PlqZqmWt",
    encryption_salt: "vIeLihup"

  plug Tmate.Router
end
