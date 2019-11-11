defmodule TmateWeb.StaticPageController do
  use TmateWeb, :controller

  def home(conn, _params) do
    conn
    |> put_layout("static.html")
    |> render("home.html")
  end
end
