defmodule Tmate.Proxy.Endpoint do
  use GenServer
  require Logger

  alias Tmate.Repo
  alias Tmate.Session
  alias Tmate.Identity
  alias Tmate.Event

  # import Ecto.Query
  # import Ecto.Changeset

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, []}
  end

  def call(endpoint, args) do
    {:reply, GenServer.call(endpoint, {:call, args}, :infinity)}
  end

  def handle_call({:call, args}, _from, state) do
    case args do
      {:event, timestamp, event_type, entity_id, params} ->
        {:ok, ecto_timestamp} = Ecto.DateTime.cast(timestamp)
        record_event(event_type, entity_id, params, ecto_timestamp)
        handle_event(event_type, entity_id, params, ecto_timestamp)
        {:reply, :ok, state}
    end
  end

  defp record_event(event_type, entity_id, params, timestamp) do
    event_params = %{type: Atom.to_string(event_type), entity_id: entity_id,
                     params: params, timestamp: timestamp}
    Event.changeset(%Event{}, event_params) |> Repo.insert!
  end

  defp handle_event(:register_session, id,
                    %{ip_address: ip_address, pubkey: pubkey,
                      ws_base_url: ws_base_url,
                      stoken: stoken, stoken_ro: stoken_ro},
                    timestamp) do
    identity = Tmate.EctoHelpers.get_or_create!(Identity, pubkey: pubkey)

    session_params = %{id: id, host_identity_id: identity.id, host_last_ip: ip_address,
                       ws_base_url: ws_base_url,
                       stoken: stoken, stoken_ro: stoken_ro, created_at: timestamp}
    Session.changeset(%Session{}, session_params) |> Repo.insert!

    Logger.info("New session id=#{id}")
  end

  defp handle_event(:close_session, id, %{}, timestamp) do
    Repo.delete(%Session{id: id})
    Logger.info("Closed session id=#{id}")
  end
end
