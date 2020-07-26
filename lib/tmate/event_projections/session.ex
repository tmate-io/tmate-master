defmodule Tmate.EventProjections.Session do
  require Logger

  alias Tmate.Session
  alias Tmate.Client
  alias Tmate.Repo
  alias Tmate.Util.EctoHelpers

  import Ecto.Query

  # handle_event() is run withing a Repo.transaction()

  # Events are ordered for a given generation.
  # This is useful when the tmate client reconnects on an other server.
  # Consider this timeline:
  # * client connects to server A
  # * server A sends the session_register event. (generation=1)
  # * client reconnects to server B
  # * server B sends the session_register,reconnected. (generation=2)
  # * server A sends a disconnection event. (generation=1)
  # We need to throw away the last disconnect event. Thankfully,
  # the events have generation numbers. Generations are incremented
  # upon reconnections.
  # If we receive an even with a younger generation that we have seen, we must
  # throw it away.

  defp when_generation_fresh(%Ecto.Changeset{
                               changes: %{generation: event_generation},
                               data: %Session{id: id, generation: session_generation}
                             }=changeset, event, func) do
    effective_gen = fn gen -> if gen == nil, do: 1, else: gen end

    if effective_gen.(session_generation) <= effective_gen.(event_generation) do
      func.(changeset)
    else
      Logger.warn("Discarding event=#{event} for session id=#{id} " <>
        "session_generation=#{inspect(session_generation)}, " <>
        "event_generation=#{inspect(event_generation)}")
    end
  end

  # This matches when there's no generation changes. Meaning the generations stay
  # the same.
  defp when_generation_fresh(changeset, _event, func) do
    func.(changeset)
  end

  defp close_session_clients(session_id) do
    from(c in Client, where: c.session_id == ^session_id) |> Repo.delete_all()
  end

  def handle_event(:session_register=event, id, timestamp,
                   %{generation: generation, ip_address: ip_address,
                     ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                     stoken: stoken, stoken_ro: stoken_ro,
                     reconnected: reconnected}) do
    if reconnected do
      Logger.info("Reconnected session id=#{id}")
    else
      Logger.info("New session id=#{id}")
    end

    session_params = %{id: id, host_last_ip: ip_address,
                       ws_url_fmt: ws_url_fmt, ssh_cmd_fmt: ssh_cmd_fmt,
                       stoken: stoken, stoken_ro: stoken_ro, created_at: timestamp,
                       generation: generation, disconnected_at: nil, closed: false}
    Session.changeset(%Session{}, session_params)
    |> EctoHelpers.get_or_insert!
    |> Session.changeset(session_params)
    |> when_generation_fresh(event, fn changeset ->
      Repo.update(changeset)
      close_session_clients(id)
    end)
  end

  def handle_event(:session_close=event, id, timestamp, %{generation: generation}) do
    Logger.info("Closed session id=#{id}")

    if (session = Repo.get(Session, id)) do
      session
      |> Session.changeset(%{generation: generation, disconnected_at: timestamp, closed: true})
      |> when_generation_fresh(event, fn changeset ->
        Repo.update(changeset)
        close_session_clients(id)
      end)
    end
  end

  def handle_event(:session_disconnect=event, id, timestamp, %{generation: generation}) do
    Logger.info("Disconnected session id=#{id}")

    if (session = Repo.get(Session, id)) do
      session
      |> Session.changeset(%{generation: generation, disconnected_at: timestamp})
      |> when_generation_fresh(event, fn changeset ->
        Repo.update(changeset)
        close_session_clients(id)
      end)
    end
  end

  def handle_event(:session_join=event, sid, timestamp, %{generation: generation,
                   id: cid, ip_address: ip_address, type: type, readonly: readonly}) do
    Logger.info("Client joined session sid=#{sid}, cid=#{cid}" <>
                ", type=#{type}, readonly=#{readonly}")

    if (session = Repo.get(Session, sid)) do
      session
      |> Session.changeset(%{generation: generation})
      |> when_generation_fresh(event, fn changeset ->
        Repo.update(changeset)

        client_params = %{id: cid, session_id: sid,
                          ip_address: ip_address, joined_at: timestamp, readonly: readonly}
        Client.changeset(%Client{}, client_params)
        |> EctoHelpers.get_or_insert!
      end)
    end
  end

  def handle_event(:session_left=event, sid, _timestamp, %{generation: generation, id: cid}) do
    Logger.info("Client left session sid=#{sid}, cid=#{cid}")

    if (session = Repo.get(Session, sid)) do
      session
      |> Session.changeset(%{generation: generation})
      |> when_generation_fresh(event, fn changeset ->
        Repo.update(changeset)

        # The session_left event can be duplicated. So we allow the record to be absent.
        %Client{id: cid}
        |> Repo.delete(stale_error_field: :_stale_)
      end)
    end
  end

  def handle_event(_, _, _, _) do
  end
end
