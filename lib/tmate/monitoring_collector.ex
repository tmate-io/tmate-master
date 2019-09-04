defmodule Tmate.MonitoringCollector do
  use Prometheus.Collector

  alias Tmate.Repo
  alias Tmate.Session
  import Ecto.Query

  # Collectors are automatically registered by the prometheus module.

  def collect_mf(_registry, callback) do
    callback.(create_gauge(:tmate_num_sessions, "Number of sessions",
                           from(s in Session, where: is_nil(s.disconnected_at),
                                              group_by: s.ssh_cmd_fmt,
                                              select: {s.ssh_cmd_fmt, count(s.id)})))

    callback.(create_gauge(:tmate_num_paired_sessions, "Number of paired sessions",
                           from(s in Session, where: is_nil(s.disconnected_at),
                                              join: assoc(s, :clients),
                                              group_by: s.ssh_cmd_fmt,
                                              select: {s.ssh_cmd_fmt, count(s.id, :distinct)})))
    :ok
  end

  def collect_metrics(_name, query) do
    Repo.all(query)
    |> Enum.map(fn {ssh_cmd_fmt, count} ->
                 {[host: Session.edge_srv_hostname(ssh_cmd_fmt)], count} end)
    |> Prometheus.Model.gauge_metrics()
  end

  defp create_gauge(name, help, data) do
    Prometheus.Model.create_mf(name, help, :gauge, __MODULE__, data)
  end
end
