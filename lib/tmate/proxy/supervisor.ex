defmodule Tmate.Proxy.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      :poolboy.child_spec(:proxy_endpoint_pool,
                          [name: {:local, :proxy_endpoint_pool},
                           worker_module: Tmate.Proxy.Endpoint,
                           size: 10, max_overflow: 10], []),
      worker(Tmate.Proxy.Listener, []),
    ]
    supervise(children, strategy: :rest_for_one)
  end
end
