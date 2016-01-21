defmodule Tmate.Identity do
  use Ecto.Model
  import Ecto.Query

  schema "identities" do
    field :type,     :string
    field :key,      :string
    field :metadata, :map

    has_many :hosted_sessions, Tmate.Session, foreign_key: :host_identity_id
    has_many :clients,         Tmate.Client
  end

  def changeset(identity, params \\ %{}) do
    identity
    |> change(params)
    |> unique_constraint(:type_key)
  end

  def key_hash(pubkey) do
    "SHA256:#{:crypto.hash(:sha256, Base.decode64!(pubkey)) |> Base.encode64}"
  end

  def type(query, type) do
    query |> where([i], i.type == ^type)
  end
end
