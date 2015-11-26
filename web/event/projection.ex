defmodule Tmate.Event.Projection do
  require Logger

  alias Tmate.Identity
  alias Tmate.Session
  alias Tmate.Client
  alias Tmate.Repo

  import Ecto.Query

  def handle_event(:session_register, id, timestamp,
                   %{ip_address: ip_address, pubkey: pubkey, ws_base_url: ws_base_url,
                     stoken: stoken, stoken_ro: stoken_ro}) do
    identity = Tmate.EctoHelpers.get_or_create!(Identity, type: "ssh", key: pubkey)

    session_params = %{id: id, host_identity_id: identity.id, host_last_ip: ip_address,
                       ws_base_url: ws_base_url,
                       stoken: stoken, stoken_ro: stoken_ro, created_at: timestamp}
    Session.changeset(%Session{}, session_params) |> Repo.insert!

    Logger.info("New session id=#{id}")
  end

  def handle_event(:session_close, id, _timestamp, _params) do
    Repo.delete(%Session{id: id})
    Logger.info("Closed session id=#{id}")
  end

  def handle_event(:session_join, sid, timestamp,
                   %{id: cid, ip_address: ip_address, type: type,
                     identity: key, readonly: readonly}) do

    client_params = %{session_id: sid, client_id: cid,
                      ip_address: ip_address, joined_at: timestamp, readonly: readonly}

    identity = Tmate.EctoHelpers.get_or_create!(Identity, type: to_string(type), key: key)
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
