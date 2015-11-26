defmodule Tmate.AuthController do
  use Tmate.Web, :controller

  require Logger

  alias Tmate.User

  def init_github_auth(conn, _params) do
    url = __MODULE__.GitHub.authorize_url!(scope: "user:email")
    conn |> redirect(external: url)
  end

  def github_callback(conn, %{"code" => code}) do
    token = __MODULE__.GitHub.get_token!(code: code)
    %{access_token: access_token} = token
    if access_token == nil, do: raise "Invalid OAuth code"

    {:ok, %{body: %{"login" => login, "name" => name}}} = OAuth2.AccessToken.get(token, "/user")
    {:ok, %{body: emails}} = OAuth2.AccessToken.get(token, "/user/emails")

    find_user_by_github_login(conn, login, access_token) ||
    continue_github_registration(conn, access_token, login, name, emails)
  end

  defp find_user_by_github_login(conn, login, _access_token) do
    user = Repo.get_by(User, github_login: login)
    if user do
      # TODO update access_token?
      conn
      |> put_session(:user_id, user.id)
      |> redirect(to: "/dashboard")
    end
  end

  defp continue_github_registration(conn, access_token, login, name, emails) do
    validated_emails = filter_emails(emails, & &1["validated"])
    conn
    |> put_session(:github_registration, %{access_token: access_token, login: login, validated_emails: validated_emails})
    |> redirect(to: "/register?#{URI.encode_query(%{type: :github, login: login, name: name, email: validated_emails |> Enum.at(0)})}")
  end

  defp filter_emails(emails, fun) do
    emails |> Enum.filter(fun) |> Enum.map(& Dict.get(&1, "email"))
  end

  def register(conn, %{}) do
    %{access_token: access_token, login: github_login, validated_emails: validated_emails} = get_session(conn, :github_registration)

    user_id = UUID.uuid1()
    Tmate.Event.emit(:user_create, user_id, %{email: email, name: name, github_login: login, github_access_token: access_token})
  end

  defmodule GitHub do
    use OAuth2.Strategy

    def client do
      {:ok, oauth_opts} = Application.fetch_env(:tmate, :github_oauth)
      {:ok, app_opts} = Application.fetch_env(:tmate, Tmate.Endpoint)

      OAuth2.Client.new(oauth_opts ++ [
        strategy: __MODULE__,
        site: "https://api.github.com",
        authorize_url: "https://github.com/login/oauth/authorize",
        token_url: "https://github.com/login/oauth/access_token",
        redirect_uri: "#{app_opts[:host_url]}#{Tmate.Router.Helpers.auth_path(Tmate.Endpoint, :github_callback)}"
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
