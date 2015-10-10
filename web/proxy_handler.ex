defmodule Tmate.ProxyHandler do
  require Logger

  alias Tmate.Repo
  alias Tmate.Session
  alias Tmate.SSHIdentity

  import Ecto.Query
  import Ecto.Changeset

  def handle_call({:register_session, ip_address, pubkey, stoken, stoken_ro}, state) do
    # TODO host_identity
    %{id: sid} = %Session{host_last_ip: ip_address, active: true,
                          stoken: stoken, stoken_ro: stoken_ro} |> Repo.insert!
    Logger.debug("New session: #{sid} #{ip_address} #{pubkey} #{stoken} #{stoken_ro}")
    {:reply, sid, state}
  end

  def handle_call({:close_session, sid}, state) do
    Repo.get!(Session, sid)
     |> change(%{active: false})
     |> Repo.update!

    Logger.debug("Closed session: #{sid}")
    {:reply, :ok, state}
  end

  def handle_call(args, state) do
    Logger.debug("Unknown proxy call: #{inspect(args)}")
    {:reply, :no_mfa, state}
  end
end
