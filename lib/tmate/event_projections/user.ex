defmodule Tmate.EventProjections.User do
  require Logger

  # alias Tmate.User

  defmacro handled_events do
    [:user_create]
  end

  def handle_event(:event_type, _uid, _timestamp, _user_params) do
  end
end
