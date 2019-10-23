defmodule Tmate.Event.Projection do
  require Logger

  require __MODULE__.Session, as: Session
  require __MODULE__.User,    as: User

  def handle_event(event_type, id, timestamp, params) when event_type in Session.handled_events do
    invoke_handler(&Session.handle_event/4, event_type, id, timestamp, params)
  end

  def handle_event(event_type, id, timestamp, params) when event_type in User.handled_events do
    invoke_handler(&User.handle_event/4, event_type, id, timestamp, params)
  end

  def handle_event(event_type, _, _, _) do
    Logger.warn("No projection for event #{event_type}")
  end

  defp invoke_handler(func, event_type, id, timestamp, params) do
    try do
      func.(event_type, id, timestamp, params)
    catch
      kind, reason ->
        evt = %{event_type: event_type, entity_id: id, timestamp: timestamp, params: params}
        Logger.error("Exception occured while handling event: #{inspect(evt)}")
        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end
end
