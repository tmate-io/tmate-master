defmodule Tmate.SSHIdentity do
  use Ecto.Model

  schema "ssh_identities" do
    belongs_to :user,            Tmate.User
    has_many   :hosted_sessions, Tmate.Session, [foreign_key: :host_identity_id]
    field      :pubkey,          :string
  end

  def changeset(ssh_identity, params \\ :empty) do
    ssh_identity
    |> change(params)
    |> unique_constraint(:pubkey)
  end
end
