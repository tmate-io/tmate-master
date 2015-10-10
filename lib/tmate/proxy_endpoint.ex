defmodule Tmate.ProxyEndpoint do
  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    :ok = :pg2.create(pg2_namespace)
    :ok = :pg2.join(pg2_namespace, self)
    {:ok, []}
  end

  def handle_info({:call, ref, from, args}, state) do
    {:reply, ret, state} = try do
       Tmate.ProxyHandler.handle_call(args, state)
    rescue
      err ->
        Logger.warn(inspect(err))
        {:reply, {:error, :exception}, state}
    end

    send(from, {:reply, ref, ret})
    {:noreply, state}
  end

  defp pg2_namespace do
    {:tmate, :master}
  end
end
