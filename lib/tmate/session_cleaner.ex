defmodule Tmate.SessionCleaner do
  require Logger

  alias Tmate.Repo
  alias Tmate.Session
  alias Tmate.Event
  import Ecto.Query

  @session_timeout_hours 3

  def prune_disconnected_sessions() do
    Logger.info("Pruning disconnected sessions since #{@session_timeout_hours} hours ago")
    from(s in Session, where: s.disconnected_at < ago(@session_timeout_hours, "hour"))
    |> Repo.delete_all
  end

  def check_for_disconnected_sessions() do
    Logger.info("Checking for disconnected sessions")
    from(s in Session, where: is_nil(s.disconnected_at),
                       select: {s.id, s.ws_url_fmt})
    |> Repo.all
    |> Enum.group_by(fn {_id, ws_url_fmt} -> ws_url_fmt end,
                     fn {id, _ws_url_fmt} -> id end)
    |> Enum.each(fn {ws_url_fmt, session_ids} ->
      base_url = Session.ws_api_baseurl(ws_url_fmt)
      check_for_disconnected_sessions(base_url, session_ids)
    end)
  end

  def check_for_disconnected_sessions(base_url, session_ids) do
    # When a websocket servers goes down, it does not notify disconnections.
    # We'll emit these missings events here.

    # 1) we get the generations of the sessions
    sid_generations =
      from(e in Event, where: e.entity_id in ^session_ids,
                       group_by: e.entity_id,
                       select: {e.entity_id, max(e.generation)})
      |> Repo.all
      |> Map.new

    # 2) we get the stale entries
    case sid_generations
      |> Map.keys
      |> get_stale_sessions(base_url) do
        {:error, reason} ->
          Logger.error("Cannot get stale sessions on #{base_url} (#{inspect(reason)})")
        {:ok, stale_ids} ->
          stale_ids
          |> Enum.map(& {&1, sid_generations[&1]})
          |> Enum.each(fn {sid, generation} ->
            # 3) emit the events for the stale entries
            Event.emit!(:session_disconnect, sid, DateTime.utc_now, generation, %{})
          end)
    end
  end

  defp get_stale_sessions(session_ids, base_url) do
    {:ok, master_options} = Application.fetch_env(:tmate, :master)
    payload = %{session_ids: session_ids, auth_key: master_options[:wsapi_key]}
    # terrible hack for now
    case json_post("#{base_url}/master_api/get_stale_sessions", payload) do
      {:ok, resp} -> {:ok, resp["stale_ids"]}
      {:error, reason} -> {:error, reason}
    end
  end

  defp json_post(url, payload) do
    payload = Jason.encode!(payload)
    headers = [{"Content-Type", "application/json"}, {"Accept", "application/json"}]
    # We need force_redirect: true, otherwise, post data doesn't get reposted.
    case HTTPoison.post(url, payload, headers, hackney: [pool: :default, force_redirect: true], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code >= 200 and status_code  < 300 ->
        {:ok, Jason.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "status=#{status_code}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
