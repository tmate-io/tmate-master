defmodule Tmate.Repo.Migrations.AddClientStats do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :left_at, :utc_datetime
      add :latency_stats, :map
    end

    alter table(:sessions) do
      add :host_latency_stats, :map
    end
  end
end
