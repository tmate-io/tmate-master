defmodule Tmate.StaticPageController do
  use Tmate.Web, :controller

  def home(conn, _params) do
    conn
    |> put_layout("static.html")
    |> render("home.html")
  end
end
