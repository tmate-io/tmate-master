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

    assert session.host_last_ip == session_event.ip_address
    assert session.stoken       == session_event.stoken
    assert session.stoken_ro    == session_event.stoken_ro
    assert session.ws_url_fmt   == session_event.ws_url_fmt
    assert session.ssh_cmd_fmt  == session_event.ssh_cmd_fmt
  end

  test "session_close" do
    session_event = emit_event(build(:event_session_register))

    session = Repo.get(Session, session_event.entity_id)
    assert session.disconnected_at == nil
    assert session.closed == false

    _client_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))

    assert Repo.one(from c in Client, select: count("*")) == 1
    close_event = emit_event(build(:event_session_close, entity_id: session_event.entity_id))
    assert Repo.one(from c in Client, select: count("*")) == 0

    session = Repo.get(Session, session_event.entity_id)
    assert session.disconnected_at != nil
    assert session.closed == true

    emit_event(close_event) # duplicate
  end

  test "session_join" do
    session_event = emit_event(build(:event_session_register))
    client1_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id))
    client2_event = emit_event(build(:event_session_join, entity_id: session_event.entity_id,
                                     type: "web", readonly: true))
    emit_event(client2_event) # test for duplicate event

    session = Repo.get(Session, session_event.entity_id)
    session = Repo.preload(session, :clients)

    clients = session.clients
    assert clients |> Enum.count == 2
    client1 = clients |> Enum.filter(& &1.id == client1_event.id) |> Enum.at(0)
    client2 = clients |> Enum.filter(& &1.id == client2_event.id) |> Enum.at(0)

    assert client1.ip_address    == client1_event.ip_address
    assert client1.readonly      == client1_event.readonly

    assert client2.ip_address    == client2_event.ip_address
    assert client2.readonly      == client2_event.readonly
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

  # TODO This test should probably be in a seperate file
  test "prune_sessions()" do
    se1 = emit_event(build(:event_session_register))
    se2 = emit_event(build(:event_session_register))
    se3 = emit_event(build(:event_session_register))

    now = DateTime.utc_now
    _de2 = emit_event(build(:event_session_disconnect, entity_id: se2.entity_id), DateTime.add(now, -1000, :second))
    _de3 = emit_event(build(:event_session_disconnect, entity_id: se3.entity_id), DateTime.add(now, -10000, :second))

    assert Repo.one(from Session, select: count("*")) == 3
    Tmate.SessionCleaner.prune_sessions({1, "hour"})

    assert (Repo.all(Session) |> Enum.map(& &1.id) |> Enum.sort()) ==
           ([se1.entity_id, se2.entity_id] |> Enum.sort())
  end

  # TODO This test should probably be in a seperate file
  test "check_for_disconnected_sessions" do
    defmodule WsApi do
      # already disconnected. Should not be checked
      @s1_id UUID.uuid1
      # will be flagged as disconnected, should be cleanup up
      @s2_id UUID.uuid1
      # will be flagged as disconnected, but reconnect events is triggered at the same time, no cleanup
      @s3_id UUID.uuid1
      # remains connected, no cleanup
      @s4_id UUID.uuid1

      def get_stale_sessions(session_ids, _base_url) do
        assert (session_ids |> Enum.sort()) ==
               ([@s2_id, @s3_id, @s4_id] |> Enum.sort())

        emit_event(build(:event_session_register, entity_id: @s3_id, generation: 2, reconnected: true))

        {:ok, [@s2_id, @s3_id]}
      end

      def session_ids() do
        [@s1_id, @s2_id, @s3_id, @s4_id]
      end
    end

    [s1_id, s2_id, s3_id, s4_id] = WsApi.session_ids()

    emit_event(build(:event_session_register, entity_id: s1_id))
    emit_event(build(:event_session_register, entity_id: s2_id))
    emit_event(build(:event_session_register, entity_id: s3_id))
    emit_event(build(:event_session_register, entity_id: s4_id))

    emit_event(build(:event_session_disconnect, entity_id: s1_id))

    assert Repo.get(Session, s1_id).disconnected_at != nil
    assert Repo.get(Session, s2_id).disconnected_at == nil
    assert Repo.get(Session, s3_id).disconnected_at == nil
    assert Repo.get(Session, s4_id).disconnected_at == nil

    Tmate.SessionCleaner.check_for_disconnected_sessions(SessionTest.WsApi)

    assert Repo.get(Session, s1_id).disconnected_at != nil
    assert Repo.get(Session, s2_id).disconnected_at != nil
    assert Repo.get(Session, s3_id).disconnected_at == nil
    assert Repo.get(Session, s4_id).disconnected_at == nil
  end
end
