defmodule Tmate.InternalApiController do
  use Tmate.Web, :controller
  alias Tmate.Session
  require Logger

  # We come here authenticated

  def webhook(conn, event_payload) do
    %{"type" => event_type, "entity_id" => entity_id,
      "timestamp" => timestamp, "generation" => generation,
      "params" => params} = event_payload

    {:ok, timestamp, 0} = DateTime.from_iso8601(timestamp)

    # Note: the incoming data is trusted, it's okay to convert to atom.
    event_type = String.to_atom(event_type)
    params = params |> map_convert_string_keys_to_atom

    Tmate.Event.emit!(event_type, entity_id, timestamp, generation, params)

    conn
    |> put_status(200)
    |> json(%{})
  end

  defp map_convert_string_keys_to_atom(map) do
    Map.new(map, fn {k, v} ->
      v = if is_map(v), do: map_convert_string_keys_to_atom(v), else: v
      {String.to_atom(k), v}
    end)
  end

  def get_session(conn, %{"token" => token}) do
    session = Repo.one(from s in Session, where: s.stoken == ^token or s.stoken_ro == ^token,
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
