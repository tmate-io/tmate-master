defmodule Tmate.InternalApiController do
  use Tmate.Web, :controller
  alias Tmate.Session
  require Logger

  alias Tmate.Util.JsonApi

  # We come here authenticated

  def webhook(conn, event_payload) do
    # Note: the incoming data is trusted, it's okay to convert to atom.
    event_payload =
      event_payload
      |> JsonApi.with_atom_keys()
      |> JsonApi.as_atom(:type)
      |> JsonApi.as_timestamp(:timestamp)

    %{type: type, entity_id: entity_id,
      timestamp: timestamp, generation: generation,
      params: params} = event_payload

    Tmate.Event.emit!(type, entity_id, timestamp, generation, params)

    conn
    |> put_status(200)
    |> json(%{})
  end

  def get_session(conn, %{"token" => token}) do
    session = Repo.one(from s in Session,
                       where: s.stoken == ^token or s.stoken_ro == ^token,
                       select: %{id: s.id,
                                 ssh_cmd_fmt: s.ssh_cmd_fmt,
                                 created_at: s.created_at,
                                 disconnected_at: s.disconnected_at,
                                 closed: s.closed},
                       limit: 1)
    if session do
      conn
      |> json(session)
    else
      conn
      |> put_status(404)
      |> json(%{error: "not found"})
    end
  end
end
