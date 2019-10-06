defmodule Tmate.Event do
  use Tmate.Web, :model
  alias Tmate.Event
  import Ecto.Query
  alias Tmate.Repo

  require Logger

  schema "events" do
    field :type,       :string
    field :entity_id,  Ecto.UUID
    field :timestamp,  :utc_datetime
    field :generation, :integer
    field :params,     :map
  end

  def changeset(model, params \\ %{}) do
    model
    |> change(params)
  end

  # def emit!(event_type, entity_id, params) do
    # now = DateTime.utc_now
    # emit!(event_type, entity_id, now, nil, params)
  # end

  # Events are ordered for a given generation.
  # This is useful when the tmate client reconnects on an other server.
  # Consider this timeline:
  # * client connects to server A
  # * server A sends the session_register event. (generation=1)
  # * client reconnects to server B
  # * server B sends the session_register,reconnected. (generation=2)
  # * server A sends a disconnection event. (generation=1)
  # We need to throw away the last disconnect event. Thankfully,
  # the events have generation numbers. Generations are incremented
  # upon reconnections.
  # If we receive an even with a younger generation that we have seen, we must
  # throw it away.
  def emit!(event_type, entity_id, timestamp, generation, params) do
    # generation == 1 will be stored as nil (easier to migrate, and maybe it's
    # more efficient storage wise).
    stored_generation = if generation == 1, do: nil, else: generation

    # 1. Save the event, regardless if it's stale
    timestamp = DateTime.truncate(timestamp, :second)
    event_params = %{type: Atom.to_string(event_type), entity_id: entity_id,
                     timestamp: timestamp, generation: stored_generation, params: params}
    Event.changeset(%Event{}, event_params) |> Repo.insert!

    Repo.transaction fn ->
      # 2. Process the event
      __MODULE__.Projection.handle_event(event_type, entity_id, timestamp, params)

      # 3. Check if the event is from the latest generation
      #
      # TODO This is racy. There's a window for an old generation event
      # to get committed after a new generation event.
      # We would need a lock around the max_generation read and the commit
      # Also, this can get bad performance-wise.
      max_generation = Repo.one(from e in Event, where: e.entity_id == ^entity_id,
                                select: max(e.generation)) || 1
      if (generation < max_generation) do
        Logger.info("Discarding stale event (:#{event_type})")
        Repo.rollback(:stale)
      end
    end
  end
end
