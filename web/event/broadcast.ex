defmodule Tmate.Event.Broadcast do
  def handle_event(event_type, entity_id, timestamp, params) do
    _event = {event_type, entity_id, timestamp, params}
  end
end
