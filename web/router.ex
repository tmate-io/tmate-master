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

  scope "/api", Tmate do
    pipe_through :api

    get "/dashboard", DashboardController, :show
  end

  scope "/", Tmate do
    pipe_through :browser

    get "/*path", PageController, :show
  end
end
