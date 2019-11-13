defmodule Tmate.EventProjections.User do
  alias Tmate.Util.EctoHelpers
  alias Tmate.User
  alias Tmate.Repo
  import Ecto.Changeset
  require Logger

  def handle_event(:user_create, user_id, timestamp, params) do
    %User{id: user_id}
    |> change(params)
    |> put_change(:created_at, timestamp)
    |> User.changeset()
    |> EctoHelpers.get_or_insert!
  end

  def handle_event(:expire_user, user_id, _timestamp, _params) do
    %User{id: user_id} |> Repo.delete(stale_error_field: :_stale_)
  end


  def handle_event(:email_api_key, user_id, _timestamp, _params) do
    user = Repo.get!(User, user_id)
    Tmate.UserMailer.api_key_email(user)
    |> Tmate.Mailer.deliver_now()
  end

  def handle_event(:session_register, _sid, timestamp,
                   %{stoken: stoken, stoken_ro: stoken_ro}) do
    get_username_from = fn token ->
      case String.split(token, "/") do
        [username, _session_name] -> username
        _ -> nil
      end
    end

    username = get_username_from.(stoken) || get_username_from.(stoken_ro)
    cond do
      username == nil -> nil
      user = Repo.get_by(User, username: username) ->
        user
        |> User.seen(timestamp)
        |> Repo.update()
      true ->
        Logger.warn("Username not found: #{username}")
    end
  end

  def handle_event(_, _, _, _) do
  end
end
