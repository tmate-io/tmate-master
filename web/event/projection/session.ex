defmodule Tmate.Event.Projection.Session do
  require Logger

  alias Tmate.Identity
  alias Tmate.Session
  alias Tmate.Client
  alias Tmate.Repo

  import Ecto.Query

  defmacro handled_events do
    [:session_register, :session_open, :session_close,
     :session_join, :session_left, :session_stats]
  end

  defp get_or_insert_identity!(type, key) do
    params = case type do
      "ssh" -> %{type: type, key: Identity.key_hash(key), metadata: %{pubkey: key}}
      _ -> %{type: type, key: key}
    end

    identity = Identity.changeset(%Identity{}, params)
    Tmate.EctoHelpers.get_or_insert!(identity, [:type, :key])
  end

  defp close_session_clients(session_id, timestamp) do
    from(c in Client, where: c.session_id == ^session_id and is_nil(c.left_at))
    |> Repo.update_all(set: [left_at: timestamp])
  end

  def handle_event(:session_register, id, timestamp, params) do
    handle_event(:session_open, id, timestamp, params)
  end

  def handle_event(:session_open, id, timestamp,
                   %{ip_address: ip_address, pubkey: pubkey,
                     ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                     stoken: stoken, stoken_ro: stoken_ro}=params) do
    identity = get_or_insert_identity!("ssh", pubkey)

    session_params = %{id: id, host_identity_id: identity.id, host_last_ip: ip_address,
                       ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                       stoken: stoken, stoken_ro: stoken_ro, created_at: timestamp}
    Session.changeset(%Session{}, session_params) |> Tmate.EctoHelpers.get_or_insert!

    if params[:reconnected] do
      close_session_clients(id, timestamp)
    end

    Logger.info("New session id=#{id}")
  end

  def handle_event(:session_close, id, timestamp, _params) do
    Repo.transaction fn ->
      close_session_clients(id, timestamp)
      Session.changeset(%Session{id: id}, %{closed_at: timestamp}) |> Repo.update
    end
    Logger.info("Closed session id=#{id}")
  end

  def handle_event(:session_join, sid, timestamp,
                   %{id: cid, ip_address: ip_address, type: type,
                     identity: key, readonly: readonly}) do
    client_params = %{id: cid, session_id: sid,
                      ip_address: ip_address, joined_at: timestamp, readonly: readonly}

    identity = get_or_insert_identity!(to_string(type), key)
    client_params = Map.merge(client_params, %{identity_id: identity.id})

    Client.changeset(%Client{}, client_params) |> Repo.insert!
    Logger.info("Client joined session sid=#{sid}, cid=#{cid}")
  end

  def handle_event(:session_left, sid, timestamp, %{id: cid}) do
    Client.changeset(%Client{id: cid}, %{left_at: timestamp}) |> Repo.update
    Logger.info("Client left session sid=#{sid}, cid=#{cid}")
  end

  def handle_event(:session_stats, sid, _timestamp, %{id: cid, latency: latency_stats}) do
    case cid do
      nil ->
        Session.changeset(%Session{id: sid}, %{host_latency_stats: latency_stats}) |> Repo.update
      _ ->
        Client.changeset(%Client{id: cid}, %{latency_stats: latency_stats}) |> Repo.update
    end
  end
end
