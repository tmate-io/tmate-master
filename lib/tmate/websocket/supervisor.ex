defmodule Tmate.Websocket.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      :poolboy.child_spec(:websocket_endpoint_pool,
                          [name: {:local, :websocket_endpoint_pool},
                           worker_module: Tmate.Websocket.Endpoint,
                           size: 10, max_overflow: 10], []),
      worker(Tmate.Websocket.Listener, []),
    ]
    supervise(children, strategy: :rest_for_one)
  end
end
