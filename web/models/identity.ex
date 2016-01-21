defmodule Tmate.Identity do
  use Ecto.Model

  schema "identities" do
    field :type, :string
    field :key,  :string
    field :hash, :string

    has_many :hosted_sessions, Tmate.Session, foreign_key: :host_identity_id
    has_many :clients,         Tmate.Client
  end

  def changeset(identity, params \\ %{}) do
    identity
    |> change(params)
    |> update_hash
    |> unique_constraint(:hash)
  end

  defp update_hash(changeset) do
    if get_change(changeset, :type) || get_change(changeset, :key) do
      {_, type} = fetch_field(changeset, :type)
      {_, key} = fetch_field(changeset, :key)
      changeset |> put_change(:hash, get_hash(type, key))
    else
      changeset
    end
  end

  defp get_hash(type, key) do
    hash = :crypto.hash(:sha256, key) |> Base.encode64
    "#{type}:SHA256:#{hash}"
  end
end
