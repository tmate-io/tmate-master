defmodule Tmate.Proxy.Endpoint do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, []}
  end

  def call(endpoint, args) do
    {:reply, GenServer.call(endpoint, {:call, args}, :infinity)}
  end

  def handle_call({:call, {:event, timestamp, event_type, entity_id, params}}, _from, state) do
    {:ok, ecto_timestamp} = Ecto.DateTime.cast(timestamp)
    # TODO GenEvent?
    args = [event_type, entity_id, ecto_timestamp, params]
    [Tmate.Proxy.Event.Store,
     Tmate.Proxy.Event.Projection,
     Tmate.Proxy.Event.Broadcast]
    |> Enum.each &apply(&1, :handle_event, args)
    {:reply, :ok, state}
  end
end
