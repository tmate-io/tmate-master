defmodule Tmate.Event.Projection.Session do
  require Logger

  alias Tmate.Identity
  alias Tmate.Session
  alias Tmate.Client
  alias Tmate.Repo

  import Ecto.Query

  defmacro handled_events do
    [:session_register, :session_open, :session_close, :session_disconnect,
     :session_join, :session_left]
  end

  defp get_or_insert_identity!(type, key) do
    params = case type do
      "ssh" -> %{type: type, key: Identity.key_hash(key), metadata: %{pubkey: key}}
      _ -> %{type: type, key: key}
    end

    identity = Identity.changeset(%Identity{}, params)
    Tmate.EctoHelpers.get_or_insert!(identity, [:type, :key])
  end

  defp close_session_clients(session_id) do
    from(c in Client, where: c.session_id == ^session_id) |> Repo.delete_all()
  end

  def handle_event(:session_register, id, timestamp, params) do
    handle_event(:session_open, id, timestamp, params)
  end

  def handle_event(:session_open, id, timestamp,
                   %{ip_address: ip_address, pubkey: pubkey,
                     ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                     stoken: stoken, stoken_ro: stoken_ro,
                     reconnected: reconnected}=_params) do
    if reconnected do
      Logger.info("Reconnected session id=#{id}")
    else
      Logger.info("New session id=#{id}")
    end

    Repo.transaction fn ->
      identity = get_or_insert_identity!("ssh", pubkey)

      session_params = %{id: id, host_identity_id: identity.id, host_last_ip: ip_address,
                         ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                         stoken: stoken, stoken_ro: stoken_ro, created_at: timestamp,
                         disconnected_at: nil, closed: false}
      Session.changeset(%Session{}, session_params)
      |> Tmate.EctoHelpers.get_or_insert!
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
                   %{id: cid, ip_address: ip_address, type: type,
                     identity: key, readonly: readonly}) do
    Logger.info("Client joined session sid=#{sid}, cid=#{cid}")

    client_params = %{id: cid, session_id: sid,
                      ip_address: ip_address, joined_at: timestamp, readonly: readonly}

    identity = get_or_insert_identity!(to_string(type), key)
    client_params = Map.merge(client_params, %{identity_id: identity.id})

    Client.changeset(%Client{}, client_params) |> Tmate.EctoHelpers.get_or_insert!
  end

  def handle_event(:session_left, sid, _timestamp, %{id: cid}) do
    Logger.info("Client left session sid=#{sid}, cid=#{cid}")

    # The session_left can be duplicated. So we allow the record to be absent.
    %Client{id: cid} |> Repo.delete(stale_error_field: :_stale_)
  end
end
