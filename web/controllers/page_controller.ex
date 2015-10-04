defmodule Tmate.PageController do
  use Tmate.Web, :controller

  def show(conn, _params) do
    render conn, "show.html"
  end
end
