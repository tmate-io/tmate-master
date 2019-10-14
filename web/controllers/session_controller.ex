defmodule Tmate.SessionController do
  use Tmate.Web, :controller

  require Logger

  alias Tmate.Repo
  alias Tmate.Session
  import Ecto.Query

  def show(conn, %{"token" => token}) do
    session = Repo.one(from s in Session, where: s.stoken == ^token or s.stoken_ro == ^token,
                                          select: %{ws_url_fmt: s.ws_url_fmt,
                                                    ssh_cmd_fmt: s.ssh_cmd_fmt,
                                                    created_at: s.created_at,
                                                    disconnected_at: s.disconnected_at,
                                                    closed: s.closed},
                                          limit: 1)
    if session do
      # Compat for the UI
      closed_at = if session.closed, do: session.disconnected_at, else: nil
      session = Map.merge(session, %{closed_at: closed_at})

      conn
      |> json(session)
    else
      :timer.sleep(:crypto.rand_uniform(50, 200))
      conn
      |> put_status(404)
      |> json(%{error: "not found"})
    end
  end
end
