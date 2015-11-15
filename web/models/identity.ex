defmodule Tmate.Identity do
  use Ecto.Model

  schema "identities" do
    belongs_to :user,            Tmate.User
    field      :pubkey,          :string

    has_many   :hosted_sessions, Tmate.Session, foreign_key: :host_identity_id
    has_many   :clients,         Tmate.Client
  end

  def changeset(identity, params \\ :empty) do
    identity
    |> change(params)
    |> unique_constraint(:pubkey)
  end
end
