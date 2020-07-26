defmodule Tmate.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tmate.Event
  import Ecto.Query
  alias Tmate.Repo

  require Logger

  schema "events" do
    field :type,       :string
    field :entity_id,  Ecto.UUID
    field :timestamp,  :utc_datetime
    field :params,     :map
  end

  def changeset(model, params \\ %{}) do
    model
    |> change(params)
  end

  def emit!(event_type, entity_id, timestamp, params) do
    timestamp = DateTime.truncate(timestamp, :second)
    event_params = %{type: Atom.to_string(event_type), entity_id: entity_id,
                     timestamp: timestamp, params: params}
    Repo.transaction fn ->
      Event.changeset(%Event{}, event_params) |> Repo.insert!
      Tmate.EventProjections.handle_event(event_type, entity_id, timestamp, params)
    end
  end

  def emit!(event_type, entity_id, timestamp, generation, params) do
    # generation == 1 will be stored as nil (easier to migrate, and maybe it's
    # more efficient storage wise).
    generation = if generation == 1, do: nil, else: generation

    # Turns out, trying to order event by looking at the Event table was a
    # mistake: performance were terrible.
    # generations are only useful for sessions, and we'll deal with that in the
    # session handlers.
    emit!(event_type, entity_id, timestamp, Map.merge(params, %{generation: generation}))
  end

  def emit!(event_type, entity_id, params) do
    now = DateTime.utc_now
    emit!(event_type, entity_id, now, params)
  end
end
