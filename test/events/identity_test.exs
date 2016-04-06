defmodule IdentityTest do
  use Tmate.EventCase, async: true

  alias Tmate.Session
  alias Tmate.Identity
  alias Tmate.Client

  test "identity with really long ssh keys", context do
    session_event = build(:event_session_register, pubkey: Base.encode64(String.duplicate("X", 10000)))
    emit_event(context, session_event)

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :host_identity)

    assert session.host_identity.type == "ssh"
    assert session.host_identity.metadata["pubkey"] == session_event.pubkey
  end

  test "identity should be singleton", context do
    session1_event = emit_event(context, build(:event_session_register))
    client1_event = emit_event(context, build(:event_session_join, entity_id: session1_event.entity_id))

    pubkey1 = session1_event.pubkey
    pubkey2 = client1_event.identity

    session2_event = emit_event(context, build(:event_session_register, pubkey: pubkey2))
    _client2_event = emit_event(context, build(:event_session_join, entity_id: session2_event.entity_id, identity: pubkey1))

    assert Repo.one(from Session, select: count("*")) == 2
    assert Repo.one(from Identity, select: count("*")) == 2
    assert Repo.one(from Client, select: count("*")) == 2
  end
end
