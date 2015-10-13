defmodule Tmate.ProxyHandler do
  require Logger

  alias Tmate.Repo
  alias Tmate.Session
  alias Tmate.SSHIdentity

  import Ecto.Query
  import Ecto.Changeset

  def handle_call({:register_session, ip_address, pubkey, stoken, stoken_ro}, state) do
    identity = Tmate.EctoHelpers.get_or_create!(SSHIdentity, pubkey: pubkey)

    session_params = %{host_identity_id: identity.id, host_last_ip: ip_address,
                       stoken: stoken, stoken_ro: stoken_ro}
    %{id: sid} = Session.changeset(%Session{}, session_params) |> Repo.insert!

    Logger.info("New session id=#{sid} rw=#{stoken} ro=#{stoken_ro}")
    {:reply, {:ok, sid}, state}
  end

  def handle_call({:close_session, sid}, state) do
    Repo.get!(Session, sid)
    |> change(%{closed_at: Ecto.DateTime.from_erl(:erlang.universaltime)})
    |> Repo.update!

    Logger.info("Closed session id=#{sid}")
    {:reply, :ok, state}
  end

  def handle_call(args, state) do
    Logger.warn("Unknown proxy call: #{inspect(args)}")
    {:reply, {:error, :no_mfa}, state}
  end
end
