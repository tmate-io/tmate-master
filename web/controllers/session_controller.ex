defmodule Tmate.SessionController do
  use Tmate.Web, :controller

  require Logger

  alias Tmate.Repo
  alias Tmate.Session
  import Ecto.Query

  def show(conn, %{"token" => token}) do
    # Remove "ro-" prefix, it's just sugar.
    token = case token do
      "ro-" <> rest -> rest
      rest -> rest
    end

    session = Repo.one(from s in Session, where: s.stoken == ^token or s.stoken_ro == ^token,
                                          select: %{ws_base_url: s.ws_base_url,
                                                    created_at: s.created_at,
                                                    closed_at: s.closed_at},
                                          limit: 1)

    if session do
      conn
      |> json session
    else
      conn
      |> put_status(404)
      |> json %{error: "not found"}
    end
  end
end
