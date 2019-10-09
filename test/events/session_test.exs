defmodule SessionTest do
  use Tmate.EventCase, async: true

  alias Tmate.Session
  alias Tmate.Client

  test "session_register" do
    session_event = build(:event_session_register)

    emit_event(session_event)
    assert Repo.one(from Session, select: count("*")) == 1

    emit_event(session_event) # duplicate event, should be okay
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

  test "session_close" do
    session_event = emit_event(build(:event_session_register))

    _client_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))

    assert Repo.one(from c in Client, select: count("*")) == 1
    close_event = emit_event(build(:event_session_close, entity_id: session_event.entity_id))
    assert Repo.one(from c in Client, select: count("*")) == 0

    session = Repo.get(Session, session_event.entity_id)
    assert session == nil

    emit_event(close_event) # duplicate
  end

  test "session_join" do
    session_event = emit_event(build(:event_session_register))
    client1_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))
    client2_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id,
                                     type: "web", identity: "xxx", readonly: true))
    emit_event(client2_event) # test for duplicate event

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)

    clients = session.clients
    assert clients |> Enum.count == 2
    client1 = clients |> Enum.filter(& &1.id == client1_event.id) |> Enum.at(0)
    client2 = clients |> Enum.filter(& &1.id == client2_event.id) |> Enum.at(0)
    client1 = Repo.preload(client1, :identity)
    client2 = Repo.preload(client2, :identity)

    assert client1.ip_address    == client1_event.ip_address
    assert client1.readonly      == client1_event.readonly
    assert client1.identity.type == client1_event.type
    assert client1.identity.metadata["pubkey"] == client1_event.identity

    assert client2.ip_address    == client2_event.ip_address
    assert client2.readonly      == client2_event.readonly
    assert client2.identity.type == client2_event.type
    assert client2.identity.key  == client2_event.identity
  end

  test "session_left" do
    session_event = emit_event(build(:event_session_register))
    _client1_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))
    client2_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)
    assert session.clients |> Enum.count == 2

    left_event = emit_event(build(:event_session_left, entity_id: session_event.entity_id, id: client2_event.id))

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)
    assert session.clients |> Enum.count == 1

    emit_event(left_event) # duplicate event

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)
    assert session.clients |> Enum.count == 1
  end

  test "session reconnect" do
    session_event = emit_event(build(:event_session_register))

    assert Repo.get(Session, session_event.entity_id).disconnected_at == nil
    _disconnect_event = emit_event(build(:event_session_disconnect, entity_id: session_event.entity_id))
    assert Repo.get(Session, session_event.entity_id).disconnected_at != nil

    session_event = emit_event(build(:event_session_register, entity_id: session_event.entity_id,
                                      reconnected: true, ssh_cmd_fmt: "new_host"))
    assert Repo.get(Session, session_event.entity_id).disconnected_at == nil
    assert Repo.get(Session, session_event.entity_id).ssh_cmd_fmt == "new_host"
  end

  test "session_disconnect/reconnect with mix generations" do
    session_event = emit_event(build(:event_session_register, generation: 1))
    _reconnect_event = emit_event(build(:event_session_register, entity_id: session_event.entity_id, generation: 2))

    _client1_event = emit_event(build(:event_session_disconnect, entity_id: session_event.entity_id, generation: 1))

    _client1_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id, generation: 1))

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)
    assert session.clients |> Enum.count == 0

    _client1_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id, generation: 2))

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)
    assert session.clients |> Enum.count == 1
  end
end
