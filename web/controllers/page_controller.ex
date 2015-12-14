defmodule Tmate.PageController do
  use Tmate.Web, :controller

  def show(conn, _params) do
    # conn = set_identity(conn)
    render(conn, "show.html")
  end

  defp set_identity(conn) do
    identity = get_session(conn, :identity)
    if identity == nil do
      identity = UUID.uuid1()
      conn = put_session(conn, :identity, identity)
    end
    conn
  end
end
