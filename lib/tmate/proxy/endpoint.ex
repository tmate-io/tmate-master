defmodule Tmate.Proxy.Endpoint do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, []}
  end

  def call(endpoint, args) do
    {:reply, GenServer.call(endpoint, args, :infinity)}
  end

  def handle_call(args, _from, state) do
    handle_call(args, state)
  end

  def handle_call({:event, timestamp, event_type, entity_id, params}, state) do
    {:ok, ecto_timestamp} = Ecto.DateTime.cast(timestamp)
    Tmate.Event.emit!(event_type, entity_id, ecto_timestamp, params)
    {:reply, :ok, state}
  end

  def handle_call({:identify_client, token, username, ip_address, pubkey}, state) do
    token_key = "identify_token:#{token}"
    stdout = case Tmate.Redis.command(["GET", token_key]) do
      {:ok, nil} -> "Invalid identification :(\nYou may try again"
      {:ok, identity} ->
        Tmate.Event.emit!(:associate_ssh_identity, identity,
                         %{username: username, ip_address: ip_address, pubkey: pubkey})
        Tmate.Redis.command(["DEL", token_key]) # Ok if fails. TTL will kill it.
        greeting()
    end
    {:reply, {:ok, stdout}, state}
  end

  defp greeting do
    ["Sweet :)", "That worked :)", "All good!"] |> Enum.shuffle |> hd
  end
end
