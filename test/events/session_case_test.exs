defmodule SessionCaseTest do
  use Tmate.ModelCase

  alias Tmate.Session
  alias Tmate.Identity
  alias Tmate.Client

  test "event session_join" do
    session_event = build(:event_session_register)

    emit_event(session_event)
    assert Repo.one(from Session, select: count("*")) == 1

    # guard against dup events
    emit_event(session_event)
    assert Repo.one(from Session, select: count("*")) == 1

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :host_identity)

    assert session.host_last_ip == session_event.ip_address
    assert session.stoken       == session_event.stoken
    assert session.stoken_ro    == session_event.stoken_ro
    assert session.ws_url_fmt   == session_event.ws_url_fmt
    assert session.ssh_cmd_fmt  == session_event.ssh_cmd_fmt
    assert session.host_identity.type == "ssh"
    assert session.host_identity.metadata["pubkey"] == session_event.pubkey
  end

  test "really long ssh keys" do
    session_event = build(:event_session_register, pubkey: Base.encode64(String.duplicate("X", 10000)))
    emit_event(session_event)

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :host_identity)

    assert session.host_identity.type == "ssh"
    assert session.host_identity.metadata["pubkey"] == session_event.pubkey
  end

  test "event session_close" do
    session_event = emit_event(build(:event_session_register))

    session = Repo.get(Session, session_event.entity_id)
    assert session.closed_at == nil

    _close_event = emit_event(build(:event_session_close, entity_id: session.id))

    session = Repo.get(Session, session_event.entity_id)
    assert session.closed_at != nil
  end

  test "event session_close remove clients" do
    session_event = emit_event(build(:event_session_register))
    _client_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))

    assert Repo.one(from c in Client, where: is_nil(c.left_at), select: count("*")) == 1
    _close_event = emit_event(build(:event_session_close, entity_id: session_event.entity_id))
    assert Repo.one(from c in Client, where: is_nil(c.left_at), select: count("*")) == 0
  end

  test "client join" do
    session_event = emit_event(build(:event_session_register))
    client1_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))
    client2_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id,
                                     type: "web", identity: "xxx", readonly: true))

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)

    clients = session.clients |> Enum.sort_by(& &1.client_id)
    assert clients |> Enum.count == 2
    client1 = clients |> Enum.at(0)
    client2 = clients |> Enum.at(1)
    client1 = Repo.preload(client1, :identity)
    client2 = Repo.preload(client2, :identity)

    assert client1.client_id     == client1_event.id
    assert client1.ip_address    == client1_event.ip_address
    assert client1.readonly      == client1_event.readonly
    assert client1.identity.type == client1_event.type
    assert client1.identity.metadata["pubkey"] == client1_event.identity

    assert client2.client_id     == client2_event.id
    assert client2.ip_address    == client2_event.ip_address
    assert client2.readonly      == client2_event.readonly
    assert client2.identity.type == client2_event.type
    assert client2.identity.key  == client2_event.identity
  end

  test "client left" do
    session_event = emit_event(build(:event_session_register))
    _client1_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))
    client2_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))

    client_query = from c in Client, where: is_nil(c.left_at)

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, clients: client_query)
    assert session.clients |> Enum.count == 2

    _close_event = emit_event(build(:event_session_left, entity_id: session_event.entity_id, id: client2_event.id))

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, clients: client_query)
    assert session.clients |> Enum.count == 1
  end

  test "identity singleton" do
    session1_event = emit_event(build(:event_session_register))
    client1_event = emit_event(build(:event_session_join, entity_id: session1_event.entity_id))

    pubkey1 = session1_event.pubkey
    pubkey2 = client1_event.identity

    session2_event = emit_event(build(:event_session_register, pubkey: pubkey2))
    _client2_event = emit_event(build(:event_session_join, entity_id: session2_event.entity_id, identity: pubkey1))

    assert Repo.one(from Session, select: count("*")) == 2
    assert Repo.one(from Identity, select: count("*")) == 2
    assert Repo.one(from Client, select: count("*")) == 2
  end
end
