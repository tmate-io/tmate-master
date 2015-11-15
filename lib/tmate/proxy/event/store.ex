defmodule Tmate.Proxy.Event.Store do
  alias Tmate.Event
  alias Tmate.Repo

  def handle_event(event_type, entity_id, timestamp, params) do
    event_params = %{type: Atom.to_string(event_type), entity_id: entity_id,
                     params: params, timestamp: timestamp}
    Event.changeset(%Event{}, event_params) |> Repo.insert!
  end
end
