defmodule Tmate.SSHIdentity do
  use Ecto.Model

  schema "ssh_identities" do
    belongs_to :user, Tmate.User
    has_many :hosted_sessions, Tmate.Session, [foreign_key: :host_identity_id]
    field :pubkey, :string
    timestamps
  end
end
