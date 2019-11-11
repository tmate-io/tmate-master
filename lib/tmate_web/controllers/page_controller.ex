defmodule TmateWeb.PageController do
  use TmateWeb, :controller

  def show(conn, _params) do
    render(conn, "index.html")
  end
end
