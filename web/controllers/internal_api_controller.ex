defmodule Tmate.InternalApiController do
  use Tmate.Web, :controller
  require Logger

  def webhook(conn, event_payload) do
    %{"type" => event_type, "entity_id" => entity_id,
      "timestamp" => timestamp, "userdata" => userdata,
      "params" => params} = event_payload

    {:ok, master_options} = Application.fetch_env(:tmate, :master)
    if Plug.Crypto.secure_compare(userdata, master_options[:wsapi_key]) do
      {:ok, timestamp, 0} = DateTime.from_iso8601(timestamp)
      timestamp = DateTime.truncate(timestamp, :second)
      event_type = String.to_atom(event_type)
      params = params |> map_convert_string_keys_to_atom

      Tmate.Event.emit!(event_type, entity_id, timestamp, params)

      conn
      |> put_status(200)
      |> json(%{})
    else
      conn
      |> put_status(403)
      |> json(%{error: "Bad key"})
    end
  end

  defp map_convert_string_keys_to_atom(map) do
    Map.new(map, fn {k, v} ->
      v = if is_map(v), do: map_convert_string_keys_to_atom(v), else: v
      {String.to_atom(k), v}
    end)
  end

  #def handle_call({:identify_client, token, username, ip_address, pubkey}, state) do
  #  token_key = "identify_token:#{token}"
  #  stdout = case Tmate.Redis.command(["GET", token_key]) do
  #    {:ok, nil} -> "Invalid identification :(\nYou may try again"
  #    {:ok, identity} ->
  #      Tmate.Event.emit!(:associate_ssh_identity, identity,
  #                       %{username: username, ip_address: ip_address, pubkey: pubkey})
  #      Tmate.Redis.command(["DEL", token_key]) # Ok if fails. TTL will kill it.
  #      greeting()
  #  end
  #  {:reply, {:ok, stdout}, state}
  #end

  #defp greeting do
  #  ["Sweet :)", "That worked :)", "All good!"] |> Enum.shuffle |> hd
  #end
end
