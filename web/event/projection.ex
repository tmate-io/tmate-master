defmodule Tmate.Event.Projection do
  require Logger

  require __MODULE__.Session, as: Session
  require __MODULE__.User,    as: User

  def handle_event(event_type, id, timestamp, params) when event_type in Session.handled_events do
    Session.handle_event(event_type, id, timestamp, params)
  end

  def handle_event(event_type, id, timestamp, params) when event_type in User.handled_events do
    User.handle_event(event_type, id, timestamp, params)
  end

  def handle_event(event_type, _, _, _) do
    Logger.warn("No projection for event #{event_type}")
  end
end
