defmodule Tmate.Router do
  use Tmate.Web, :router

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
    plug Tmate.Util.PlugVerifyAuthToken, fn_opts: &Tmate.Router.internal_api_opts/0
  end

  scope "/api", Tmate do
    pipe_through :api

    get "/dashboard", DashboardController, :show
    get "/t/:token", SessionController, :show

    scope "/user" do
      post "/request_identification", UserController, :request_identification
    end

    post "/signup",          SigninController, :signup
    post "/signup/validate", SigninController, :validate
  end

  # TODO remove
  scope "/wsapi", Tmate do
    pipe_through :internal_api
    post "/webhook", InternalApiController, :webhook
    get "/session", InternalApiController, :get_session
  end

  scope "/internal_api", Tmate do
    pipe_through :internal_api
    post "/webhook", InternalApiController, :webhook
    get "/session", InternalApiController, :get_session
  end

  scope "/", Tmate do
    pipe_through :browser

    get "/signin/github/init",     SigninController, :init_github_auth
    get "/signin/github/callback", SigninController, :github_callback
    get "/signup",                 SigninController, :signup

    get "/dashboard", PageController, :show
    get "/t/:token", PageController, :show

    get "/", StaticPageController, :home
    # get "/*path", PageController, :show
  end
end
