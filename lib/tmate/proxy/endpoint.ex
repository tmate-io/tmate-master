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

  def handle_call({:event, timestamp, event_type, entity_id, params}, _from, state) do
    {:ok, ecto_timestamp} = Ecto.DateTime.cast(timestamp)
    process_event(event_type, entity_id, ecto_timestamp, params)
    {:reply, :ok, state}
  end

  def handle_call({:identify_client, token, username, ip_address, pubkey}, _from, state) do
    token_key = "identify_token:#{token}"
    stdout = case Tmate.Redis.command(["GET", token_key]) do
      {:ok, nil} -> "Invalid identification :(\nYou may try again"
      {:ok, identity} ->
        now = Ecto.DateTime.utc
        process_event(:associate_ssh_identity, identity, now,
                      %{username: username, ip_address: ip_address, pubkey: pubkey})
        Tmate.Redis.command(["DEL", token_key]) # Ok if fails. TTL will kill it.
        greeting
    end
    {:reply, {:ok, stdout}, state}
  end

  defp process_event(event_type, entity_id, ecto_timestamp, params) do
    # TODO GenEvent?
    args = [event_type, entity_id, ecto_timestamp, params]
    [Tmate.Proxy.Event.Store,
     Tmate.Proxy.Event.Projection,
     Tmate.Proxy.Event.Broadcast]
    |> Enum.each &apply(&1, :handle_event, args)
  end

  defp greeting do
    ["Sweet :)", "That worked :)", "All good!"] |> Enum.shuffle |> hd
  end
end
