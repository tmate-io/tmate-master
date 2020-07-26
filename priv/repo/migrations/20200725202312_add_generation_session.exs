defmodule Tmate.Repo.Migrations.AddGenerationSession do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :generation, :integer
    end
  end
end
