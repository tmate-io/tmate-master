defmodule Tmate.EventProjections do
  require Logger

  @handlers [
    &__MODULE__.Session.handle_event/4,
    &__MODULE__.User.handle_event/4,
  ]

  def handle_event(event_type, id, timestamp, params) do
    @handlers |> Enum.each(fn handler ->
      invoke_handler(handler, event_type, id, timestamp, params)
    end)
  end

  defp invoke_handler(func, event_type, id, timestamp, params) do
    # TODO raise after invoking all handlers
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
