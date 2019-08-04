defmodule Tmate.Repo.Migrations.ClientIdUuid do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :id, :uuid
    end

    flush()
    Ecto.Adapters.SQL.query(Tmate.Repo, "update clients set id = md5(random()::text || clock_timestamp()::text)::uuid", [])

    drop index(:clients, [:session_id, :client_id], [unique: true])
    drop index(:clients, [:client_id])

    alter table(:clients) do
      modify :id, :uuid, primary_key: true
      remove :client_id
    end
  end
end
