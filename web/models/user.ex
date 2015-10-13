defmodule Tmate.User do
  use Ecto.Model

  schema "users" do
    has_many :ssh_identities, Tmate.SSHIdentity
    has_many :sessions,       through: [:ssh_identities, :hosted_sessions]
    field    :anonymous,      :boolean
    timestamps
  end

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, [:anonymous])
  end
end
