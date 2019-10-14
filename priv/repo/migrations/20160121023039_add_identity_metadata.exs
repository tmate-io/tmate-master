defmodule Tmate.Repo.Migrations.AddMetadataIdentity do
  use Ecto.Migration

  alias Tmate.Repo
  alias Tmate.Identity

  def change do
    alter table(:identities) do
      add :metadata, :map
    end

    flush()

    Repo.all(Identity |> Identity.type("ssh"))
    |> Enum.each(fn identity ->
        identity |> migrate_ssh_key() |> Repo.update!()
    end)

    alter table(:identities) do
      modify :key, :string, size: 64, null: false
    end
  end

  defp migrate_ssh_key(identity) do
    params = case {identity.type, identity.key} do
      {"ssh", "SHA256:" <> _} -> %{}
      {"ssh", _key} -> %{key: Identity.key_hash(identity.key), metadata: %{pubkey: identity.key}}
      _ -> %{}
    end
    Identity.changeset(identity, params)
  end
end
