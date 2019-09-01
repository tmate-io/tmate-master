defmodule Tmate.RemoteIpPlug do
  require Logger
  @behaviour Plug

  # We use the PROXY protocol, but if we were to use headers,
  # we could use https://github.com/ajvondrak/remote_ip

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    conn
    |> set_proxied_remote_ip()
    |> log_remote_ip()
  end

  defp set_proxied_remote_ip(%{adapter: {_connection,
                               %{proxy_header: %{src_address: src_address}
                                =_proxy_header}=_req}}=conn) do
    %{conn | remote_ip: src_address}
  end

  defp set_proxied_remote_ip(conn) do
    conn
  end

  defp log_remote_ip(%{remote_ip: remote_ip}=conn) do
    ip = :inet_parse.ntoa(remote_ip) |> to_string
    Logger.metadata(remote_ip: ip)
    conn
  end
end
