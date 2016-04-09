defmodule Tmate.SigninController do
  use Tmate.Web, :controller

  require Logger

  alias Tmate.User

  def init_github_auth(conn, _params) do
    url = __MODULE__.OAuthGitHub.authorize_url!(scope: "user:email")
    conn |> redirect(external: url)
  end

  def github_callback(conn, %{"code" => code}) do
    token = __MODULE__.OAuthGitHub.get_token!(code: code)
    %{access_token: access_token} = token
    if access_token == nil, do: raise "Invalid OAuth code"

    Logger.info(OAuth2.AccessToken.get(token, "/user") |> inspect)

    {:ok, %{body: %{"id" => github_id, "login" => github_username}}} = OAuth2.AccessToken.get(token, "/user")
    {:ok, %{body: github_emails}} = OAuth2.AccessToken.get(token, "/user/emails")
    verified_emails = github_emails |> Enum.filter(& &1["verified"]) |> Enum.map(& Dict.get(&1, "email"))

    find_user_by_github_id(conn, github_id) ||
    continue_github_signup(conn, github_id, github_username, verified_emails)
  end

  defp find_user_by_github_id(conn, github_id) do
    user = Repo.get_by(User, github_id: github_id)
    if user do
      conn
      |> put_session(:user_id, user.id)
      |> redirect(to: "/")
    end
  end

  defp continue_github_signup(conn, github_id, username, verified_emails) do
    conn
    |> put_session(:signup, %{username: username, verified_emails: verified_emails, github_id: github_id})
    |> redirect(to: "/signup")
  end

  defp get_signup_info(conn) do
    get_session(conn, :signup) || %{username: nil, verified_emails: [], github_id: nil}
  end

  def signup(%{method: "GET"} = conn, _params) do
    %{username: username, verified_emails: emails} = get_signup_info(conn)
    signup_info = %{username: username, email: Enum.at(emails, 0)}
    signup_info = signup_info |> Enum.filter(fn {k,v} -> v end) |> Enum.into(%{})

    conn
    |> render(Tmate.PageView, "show.html", global_vars: %{signup: signup_info})
  end

  def signup(%{method: "POST"} = conn, %{"username" => username, "email" => email}) do
    %{github_id: github_id, verified_emails: verified_emails} = get_signup_info(conn)

    if Enum.find(verified_emails, & &1 == email) do
      finalize_signup(conn, %{username: username, email: email, github_id: github_id})
    else
      # XXX Send an email confirmation link
      conn
    end
  end

  def validate(conn, params) do
    changeset = User.changeset(%User{id: UUID.uuid1}, params)
    case Tmate.EctoHelpers.validate_changeset(changeset) do
      {:error, changeset} ->
        conn
        |> put_status(400)
        |> render(Tmate.ChangesetView, "error.json", changeset: changeset)
      :ok ->
        conn
        |> json(%{})
    end
  end

  defp finalize_signup(conn, user_params) do
    user_id = UUID.uuid1()
    changeset = User.changeset(%User{id: user_id}, user_params)

    case Tmate.EctoHelpers.validate_changeset(changeset) do
      {:error, changeset} ->
        Logger.warn(changeset |> inspect)
        conn
        |> put_status(400)
        |> render(Tmate.ChangesetView, "error.json", changeset: changeset)
      :ok ->
        Tmate.Event.emit!(:user_create, user_id, changeset.changes)
        conn
        |> delete_session(:signup)
        |> put_session(:user_id, user_id)
        |> json(%{user: %{username: changeset.changes.username}})
    end
  end

  defmodule OAuthGitHub do
    use OAuth2.Strategy

    def client do
      {:ok, oauth_opts} = Application.fetch_env(:tmate, :github_oauth)
      {:ok, app_opts} = Application.fetch_env(:tmate, Tmate.Endpoint)

      OAuth2.Client.new(oauth_opts ++ [
        strategy: __MODULE__,
        site: "https://api.github.com",
        authorize_url: "https://github.com/login/oauth/authorize",
        token_url: "https://github.com/login/oauth/access_token",
        redirect_uri: "#{app_opts[:host_url]}#{Tmate.Router.Helpers.signin_path(Tmate.Endpoint, :github_callback)}"
      ])
    end

    def authorize_url!(params \\ []) do
      OAuth2.Client.authorize_url!(client, params)
    end

    # you can pass options to the underlying http library via `options` parameter
    def get_token!(params \\ [], headers \\ [], options \\ []) do
      OAuth2.Client.get_token!(client, params, headers, options)
    end

    # Strategy Callbacks

    def authorize_url(client, params) do
      OAuth2.Strategy.AuthCode.authorize_url(client, params)
    end

    def get_token(client, params, headers) do
      client
      |> put_header("Accept", "application/json")
      |> OAuth2.Strategy.AuthCode.get_token(params, headers)
    end
  end
end
