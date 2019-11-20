defmodule TmateWeb.SignUpController do
  use TmateWeb, :controller

  alias Tmate.Util.EctoHelpers
  alias Tmate.User
  alias Tmate.Repo

  require Logger

  def new(conn, _params) do
    flash_msg = get_flash(conn, :registration)

    changeset = User.changeset(%User{}, %{allow_mailing_list: true})
    conn
    |> clear_flash()
    |> render("home.html", changeset: changeset, flash_info: flash_msg)
  end

  def create(conn, %{"user"=> %{"email"=> email}=user_params}) do
    # When a user try to sign up with an email corresponding to an existing
    # verified account, we'll send the credentials that we already have.
    # Otherwise, we proceed to creating the account.
    case Repo.get_by(User, email: email) do
      %{id: user_id, verified: true} ->
        Tmate.Event.emit!(:email_api_key, user_id, %{again: true})

        conn
        |> put_flash(:registration, "Your API key has been sent to #{email}"
                               <> ". If you need a new API key, please contact us at support@tmate.io")
        |> redirect(to: "#{Routes.sign_up_path(conn, :new)}#api_key")
      %{id: user_id, verified: false} ->
        Tmate.Event.emit!(:expire_user, user_id, %{})
        create_stub(conn, user_params)
      _ ->
        create_stub(conn, user_params)
    end
  end

  defp create_stub(conn, %{"email" => email, "username" => username}=user_params) do
    case Repo.get_by(User, username: username) do
      %{id: user_id, verified: false} ->
        Tmate.Event.emit!(:expire_user, user_id, %{})
      _ -> nil
    end

    user_id = UUID.uuid1()
    changeset = User.changeset(%User{id: user_id}, user_params)

    # Note that validate_changeset() will test the uniqueness validations
    case EctoHelpers.validate_changeset(changeset) do
      {:error, changeset} ->
        Logger.warn("signup invalid: #{inspect(changeset)}")
        conn
        |> put_status(400)
        |> render("home.html", changeset: changeset, flash_info: nil)
      :ok ->
        Tmate.Event.emit!(:user_create, user_id, changeset.changes)
        Tmate.Event.emit!(:email_api_key, user_id, %{})
        conn
        |> put_flash(:registration, "Your API key has been sent to #{email}")
        |> redirect(to: "#{Routes.sign_up_path(conn, :new)}#api_key")
    end
  end
end
