defmodule Tmate.Event.Projection do
  require Logger

  alias Tmate.Identity
  alias Tmate.Session
  alias Tmate.Client
  alias Tmate.Repo

  import Ecto.Query

  defp get_or_create_identity!(type, key) do
    params = case type do
      "ssh" -> %{type: type, key: Identity.key_hash(key), metadata: %{pubkey: key}}
      _ -> %{type: type, key: key}
    end

    identity = Identity.changeset(%Identity{}, params)
    Tmate.EctoHelpers.get_or_create!(identity, [:type, :key])
  end

  def handle_event(:session_register, id, timestamp,
                   %{ip_address: ip_address, pubkey: pubkey,
                     ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                     stoken: stoken, stoken_ro: stoken_ro}) do
    identity = get_or_create_identity!("ssh", pubkey)

    session_params = %{id: id, host_identity_id: identity.id, host_last_ip: ip_address,
                       ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                       stoken: stoken, stoken_ro: stoken_ro, created_at: timestamp}
    Session.changeset(%Session{}, session_params) |> Tmate.EctoHelpers.get_or_create!

    Logger.info("New session id=#{id}")
  end

  def handle_event(:session_close, id, timestamp, _params) do
    Repo.transaction fn ->
      from(c in Client, where: c.session_id == ^id) |> Repo.delete_all
      Session.changeset(%Session{id: id}, %{closed_at: timestamp}) |> Repo.update
    end
    Logger.info("Closed session id=#{id}")
  end

  def handle_event(:session_join, sid, timestamp,
                   %{id: cid, ip_address: ip_address, type: type,
                     identity: key, readonly: readonly}) do

    client_params = %{session_id: sid, client_id: cid,
                      ip_address: ip_address, joined_at: timestamp, readonly: readonly}

    identity = get_or_create_identity!(to_string(type), key)
    client_params = Map.merge(client_params, %{identity_id: identity.id})

    Client.changeset(%Client{}, client_params) |> Repo.insert!

    Logger.info("Client joined session sid=#{sid}, cid=#{cid}")
  end

  def handle_event(:session_left, sid, _timestamp, %{id: cid}) do
    from(c in Client, where: c.session_id == ^sid and c.client_id == ^cid)
    |> Repo.delete_all
    Logger.info("Client left session sid=#{sid}, cid=#{cid}")
  end

  def handle_event(:associate_ssh_identity, web_identity, _timestamp, %{pubkey: pubkey}) do
    # TODO
    # Logger.info("Associated identities")
  end

  def handle_event(event_type, _, _, _) do
    Logger.debug("No projection for event #{event_type}")
  end
end
