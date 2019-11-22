defmodule Tmate.EventProjections.Session do
  require Logger

  alias Tmate.Session
  alias Tmate.Client
  alias Tmate.Repo
  alias Tmate.Util.EctoHelpers

  import Ecto.Query

  defp close_session_clients(session_id) do
    from(c in Client, where: c.session_id == ^session_id) |> Repo.delete_all()
  end

  def handle_event(:session_register, id, timestamp,
                   %{ip_address: ip_address,
                     ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                     stoken: stoken, stoken_ro: stoken_ro,
                     reconnected: reconnected}=_params) do
    if reconnected do
      Logger.info("Reconnected session id=#{id}")
    else
      Logger.info("New session id=#{id}")
    end

    Repo.transaction fn ->
      session_params = %{id: id, host_last_ip: ip_address,
                         ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                         stoken: stoken, stoken_ro: stoken_ro, created_at: timestamp,
                         disconnected_at: nil, closed: false}
      Session.changeset(%Session{}, session_params)
      |> EctoHelpers.get_or_insert!
      |> Session.changeset(session_params)
      |> Repo.update

      close_session_clients(id)
    end
  end

  def handle_event(:session_close, id, timestamp, _params) do
    Logger.info("Closed session id=#{id}")

    Repo.transaction fn ->
      close_session_clients(id)

      %Session{id: id}
      |> Session.changeset(%{disconnected_at: timestamp, closed: true})
      |> Repo.update()
    end
  end

  def handle_event(:session_disconnect, id, timestamp, _params) do
    Logger.info("Disconnected session id=#{id}")

    Repo.transaction fn ->
      close_session_clients(id)

      %Session{id: id}
      |> Session.changeset(%{disconnected_at: timestamp})
      |> Repo.update()
    end
  end

  def handle_event(:session_join, sid, timestamp,
                   %{id: cid, ip_address: ip_address, type: type, readonly: readonly}) do
    Logger.info("Client joined session sid=#{sid}, cid=#{cid}" <>
                ", type=#{type}, readonly=#{readonly}")

    client_params = %{id: cid, session_id: sid,
                      ip_address: ip_address, joined_at: timestamp, readonly: readonly}

    Client.changeset(%Client{}, client_params) |> EctoHelpers.get_or_insert!
  end

  def handle_event(:session_left, sid, _timestamp, %{id: cid}) do
    Logger.info("Client left session sid=#{sid}, cid=#{cid}")

    # The session_left can be duplicated. So we allow the record to be absent.
    %Client{id: cid} |> Repo.delete(stale_error_field: :_stale_)
  end

  def handle_event(_, _, _, _) do
  end
end
