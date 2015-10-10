defmodule Tmate.User do
  use Ecto.Model

  schema "users" do
    has_many :ssh_identities, Tmate.SSHIdentity
    has_many :sessions, through: [:ssh_identities, :hosted_sessions]
    timestamps
  end
end
