defmodule Tmate.User do
  use Ecto.Model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    has_many :ssh_identities, Tmate.SSHIdentity
    has_many :sessions,       through: [:ssh_identities, :hosted_sessions]
    field    :anonymous,      :boolean
    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    |> change(params)
  end
end
