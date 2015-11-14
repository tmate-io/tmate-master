defmodule Tmate.Identity do
  use Ecto.Model

  schema "identities" do
    belongs_to :user,            Tmate.User
    has_many   :hosted_sessions, Tmate.Session, [foreign_key: :host_identity_id]
    field      :pubkey,          :string
  end

  def changeset(identity, params \\ :empty) do
    identity
    |> change(params)
    |> unique_constraint(:pubkey)
  end
end
