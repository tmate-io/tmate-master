defmodule Tmate.Repo.Migrations.AddClosedAt do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :closed, :boolean, default: false
    end
  end
end
