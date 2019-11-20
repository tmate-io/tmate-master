defmodule TmateWeb.InternalApiController do
  use TmateWeb, :controller
  alias Tmate.Session
  alias Tmate.User
  require Logger
  import Ecto.Query
  alias Tmate.Repo

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
                       order_by: [desc: s.created_at],
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

  def get_named_session_prefix(conn, %{"api_key" => api_key}) do
    user = User.get_by_api_key(api_key)
    if user do
      prefix = "#{user.username}/"
      result = %{prefix: prefix}
      conn
      |> json(result)
    else
      conn
      |> put_status(404)
      |> json(%{error: "api key not found"})
    end
  end
end
