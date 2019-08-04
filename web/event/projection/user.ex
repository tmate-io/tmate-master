defmodule Tmate.Event.Projection.User do
  require Logger

  alias Tmate.User

  defmacro handled_events do
    [:user_create, :user_associate_ssh_identity]
  end

  def handle_event(:user_create, uid, _timestamp, user_params) do
    User.changeset(%User{id: uid}, user_params) |> Tmate.EctoHelpers.get_or_insert!
    Logger.info("New user id=#{uid}, username=#{user_params.username}")
  end

  def handle_event(:user_associate_ssh_identity, _web_identity, _timestamp, %{pubkey: _pubkey}) do
    # TODO
    # Logger.info("Associated identities")
  end
end
