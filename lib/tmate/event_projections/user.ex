defmodule Tmate.EventProjections.User do
  alias Tmate.Util.EctoHelpers
  alias Tmate.User
  import Ecto.Changeset

  def handle_event(:user_create, user_id, timestamp, params) do
    %User{id: user_id}
    |> change(params)
    |> put_change(:created_at, timestamp)
    |> User.changeset()
    |> EctoHelpers.get_or_insert!
  end

  def handle_event(:session_register, _sid, timestamp,
                   %{stoken: stoken, stoken_ro: stoken_ro}) do
    get_username = fn token ->
      case String.split(token, "/") do
        [username, _rest] -> username
        _ -> nil
      end
    end

    username = get_username.(stoken) || get_username.(stoken_ro)
    if (username) do
      User.get_by_username!(username) |> User.seen!(timestamp)
    end
  end

  def handle_event(_, _, _, _) do
  end
end
