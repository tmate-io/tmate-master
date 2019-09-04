defmodule Tmate.Monitoring do
  require Prometheus.Registry

  def setup do
    Tmate.Endpoint.PhoenixInstrumenter.setup()
    Tmate.PlugExporter.setup()
    Tmate.Repo.Instrumenter.setup2()
  end
end

defmodule Tmate.Endpoint.PhoenixInstrumenter do
  use Prometheus.PhoenixInstrumenter
end

defmodule Tmate.Repo.Instrumenter do
  use Prometheus.EctoInstrumenter

  def setup2() do
    setup()
    :ok = :telemetry.attach(
      "prometheus-ecto",
      [:tmate, :repo, :query],
      &__MODULE__.handle_event/4,
      %{}
    )
  end
end

# Tmate metrics are implemented in Tmate.MonitoringCollector

### Exporter

defmodule Tmate.PlugExporter do
  use Prometheus.PlugExporter
end

defmodule Tmate.Monitoring.Endpoint do
  use Plug.Router

  plug Tmate.PlugExporter

  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
