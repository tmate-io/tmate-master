defmodule TmateWeb.SignUpController do
  use TmateWeb, :controller

  alias Tmate.Util.EctoHelpers
  alias Tmate.User

  require Logger

  def new(conn, _params) do
    flash_msg = get_flash(conn, :registration)

    changeset = User.changeset(%User{}, %{allow_mailing_list: true})
    conn
    |> put_layout("static.html")
    |> clear_flash()
    |> render("new.html", changeset: changeset, flash_info: flash_msg)
  end

  def create(conn, %{"user"=> user_params}) do

  #  if email found:
  #          if not verified:
  #                  delete previous
  #                  create record
  #          if verified:
  #                  send old credentials
  #
  #  if username found:
  #          if not verified:
  #                  delete previous
  #                  create record
  #          if verified:
  #                  Error: username taken
  #
  #  send creds

    user_id = UUID.uuid1()
    %{"email" => email} = user_params
    changeset = User.changeset(%User{id: user_id}, user_params)

    case EctoHelpers.validate_changeset(changeset) do
      {:error, changeset} ->
        Logger.warn(changeset |> inspect)
        conn
        |> put_status(400)
        |> put_layout("static.html")
        |> render("new.html", changeset: changeset, flash_info: nil)
      :ok ->
        # TODO Not sure if we should be using events, it's racy.
        Tmate.Event.emit!(:user_create, user_id, changeset.changes)
        conn
        |> put_flash(:registration, "Your API key has been sent to #{email}")
        |> redirect(to: Routes.sign_up_path(conn, :new))
    end
  end
end
