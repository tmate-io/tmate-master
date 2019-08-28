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

  pipeline :ws_api do
    plug :accepts, ["json"]
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

  scope "/wsapi", Tmate do
    pipe_through :ws_api
    post "/webhook", InternalApiController, :webhook
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
