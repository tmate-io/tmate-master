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
    # TODO GenEvent?
    args = [event_type, entity_id, ecto_timestamp, params]
    [Tmate.Proxy.Event.Store,
     Tmate.Proxy.Event.Projection,
     Tmate.Proxy.Event.Broadcast]
    |> Enum.each &apply(&1, :handle_event, args)
    {:reply, :ok, state}
  end

  def handle_call({:identify_client, token, username, ip_address, pubkey}, _from, state) do
    {:reply, {:ok, greeting}, state}
  end

  defp greeting do
    ["Sweet :)", "That worked :)", "All good!"] |> Enum.shuffle |> hd
  end
end
