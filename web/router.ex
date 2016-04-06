defmodule Tmate.Router do
  use Tmate.Web, :router

  use Rollbax.Plug

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

  scope "/api", Tmate do
    pipe_through :api

    get "/dashboard", DashboardController, :show
    get "/t/:token", SessionController, :show

    scope "/user" do
      post "/request_identification", UserController, :request_identification
    end
  end

  scope "/auth", Tmate do
    pipe_through :browser

    post "/register",        AuthController, :register
    get  "/github/init",     AuthController, :init_github_auth
    get  "/github/callback", AuthController, :github_callback
  end

  scope "/", Tmate do
    pipe_through :browser

    get "/", StaticPageController, :home
    get "/*path", PageController, :show
  end
end
