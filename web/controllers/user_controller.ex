defmodule Tmate.UserController do
  use Tmate.Web, :controller

  plug :require_identity

  @token_base '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
  @token_ttl 10*60

  def require_identity(conn, []) do
    case get_session(conn, :identity) do
      nil ->
        conn
        |> halt
        |> put_status(403)
        |> json %{error: "Unauthorized"}
      identity ->
        conn
        |> assign(:identity, identity)
    end
  end

  def request_identification(conn, _params) do
    token = generate_token
    Tmate.Redis.command(["SET", "identify_token:#{token}", conn.assigns[:identity], "EX", @token_ttl])

    {:ok, ssh_opts} = Application.fetch_env(:tmate, :ssh)

    port_opts = if ssh_opts[:port] == 22, do: "", else: " -p#{ssh_opts[:port]}"
    cmd = "ssh#{port_opts} #{ssh_opts[:host]} identify #{token}"
    conn |> json %{cmd: cmd}
  end

  def generate_token do
    base_len = length(@token_base)
    (0..10)
    |> Enum.map(fn _ -> @token_base |> Enum.at(:crypto.rand_uniform(0, base_len-1)) end)
    |> to_string
  end
end
