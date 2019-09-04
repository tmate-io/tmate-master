defmodule Tmate.Repo.Migrations.AddDisconnectAt do
  use Ecto.Migration

  def change do
    # Simplify things a bit.

    Ecto.Adapters.SQL.query(Tmate.Repo, "delete from sessions where closed_at is not null", [])
    Ecto.Adapters.SQL.query(Tmate.Repo, "delete from clients where left_at is not null", [])
    flush()

    alter table(:sessions) do
      add :disconnected_at, :utc_datetime
      remove :closed_at
    end

    alter table(:clients) do
      remove :left_at
      remove :latency_stats
    end

    alter table(:sessions) do
      remove :host_latency_stats
    end

    # Assume the worst for existing sessions.
    flush()
    Ecto.Adapters.SQL.query(Tmate.Repo, "update sessions set disconnected_at = clock_timestamp()", [])

    # Note: Sessions that are disconnected for too long should be pruned
    # We could have some sort of timer
    create index(:sessions, [:disconnected_at])
  end
end
