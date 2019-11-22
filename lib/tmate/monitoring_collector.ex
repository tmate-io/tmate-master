defmodule Tmate.MonitoringCollector do
  use Prometheus.Collector

  alias Tmate.Repo
  alias Tmate.Session
  alias Tmate.User
  import Ecto.Query

  # Collectors are automatically registered by the prometheus module.

  @bucket_names %{nil => "never", 0 => "long time",
                  1 => "past year", 2 => "past month", 3 => "past week", 4 => "past day"}
  @bucket_days  [              365,                30,                7,               1]

  def collect_mf(_registry, callback) do
    {:ok, options} = Application.fetch_env(:tmate, Tmate.MonitoringCollector)
    if options[:metrics_enabled], do: collect_mf_stub(callback)
    :ok
  end

  defp collect_mf_stub(callback) do
    per_host_key_fn = & Enum.map(&1, fn {ssh_cmd_fmt, count} ->
      {[host: Session.edge_srv_hostname(ssh_cmd_fmt)], count}
    end)

    callback.(create_keyed_gauge(
      :tmate_num_sessions, "Number of sessions",
      from(s in Session, where: is_nil(s.disconnected_at),
                         group_by: s.ssh_cmd_fmt,
                         select: {s.ssh_cmd_fmt, count(s.id)}),
      per_host_key_fn))

    callback.(create_keyed_gauge(
      :tmate_num_paired_sessions, "Number of paired sessions",
      from(s in Session, where: is_nil(s.disconnected_at),
           join: assoc(s, :clients),
           group_by: s.ssh_cmd_fmt,
           select: {s.ssh_cmd_fmt, count(s.id, :distinct)}),
      per_host_key_fn))

    callback.(create_keyed_gauge(
      :tmate_num_users, "Number of users seen",
      from(u in User,
           select: %{bucket: fragment("width_bucket(?, ARRAY[?,?,?,?])",
                               u.last_seen_at,
                               # Quite terrible, we should do the quote
                               # unquote danse to deal with this (fragment
                               # and ago are macros that are capricious).
                               ago(^(@bucket_days |> Enum.at(0)), "day"),
                               ago(^(@bucket_days |> Enum.at(1)), "day"),
                               ago(^(@bucket_days |> Enum.at(2)), "day"),
                               ago(^(@bucket_days |> Enum.at(3)), "day")),
                     count: count()},
           group_by: 1),
      & Enum.map(&1, fn %{bucket: bucket_index, count: count} ->
        {[bucket: Map.get(@bucket_names, bucket_index)], count}
      end)))
  end

  defmodule KeyedGauge do
    def collect_metrics(_name, {query, key_fn}) do
      Repo.all(query)
      |> key_fn.()
      |> Prometheus.Model.gauge_metrics()
    end
  end

  defp create_keyed_gauge(name, help, query, key_fn) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__.KeyedGauge, {query, key_fn})
  end
end
