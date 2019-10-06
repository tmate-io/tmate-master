defmodule Tmate.Repo.Migrations.AddGeneration do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :generation, :integer
    end
  end
end
