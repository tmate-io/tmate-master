defmodule TmateWeb.Router do
  use TmateWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :put_secure_browser_headers
  end

  pipeline :internal_api do
    plug :accepts, ["json"]

    def internal_api_opts do
      # XXX We can't pass the auth token directly, it is not
      # necessarily defined at compile time.
      Application.fetch_env!(:tmate, :master)[:internal_api]
    end
    plug Tmate.Util.PlugVerifyAuthToken, fn_opts: &__MODULE__.internal_api_opts/0
  end

  scope "/api", TmateWeb do
    pipe_through :api

    get "/t/*token", TerminalController, :show_json
  end

  scope "/internal_api", TmateWeb do
    pipe_through :internal_api
    post "/webhook", InternalApiController, :webhook
    get "/session", InternalApiController, :get_session
    get "/named_session_prefix", InternalApiController, :get_named_session_prefix
  end

  scope "/", TmateWeb do
    pipe_through :browser

    get "/t/*token", TerminalController, :show

    get "/", SignUpController, :new
    post "/", SignUpController, :create
  end

  if Mix.env == :dev do
    # If using Phoenix
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end
end
