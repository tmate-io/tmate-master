defmodule Tmate.Redis do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, opts} = Application.fetch_env(:tmate, :redis)

    pool_opts = [
      name: {:local, :redix_poolboy},
      worker_module: Redix,
      size: opts[:pool_size],
      max_overflow: opts[:pool_max_overflow],
    ]

    children = [
      :poolboy.child_spec(:redix_poolboy, pool_opts, opts[:url])
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  def command(command) do
    :poolboy.transaction(:redix_poolboy, &Redix.command(&1, command))
  end

  def pipeline(commands) do
    :poolboy.transaction(:redix_poolboy, &Redix.pipeline(&1, commands))
  end
end
