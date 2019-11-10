defmodule Tmate.Repo.Migrations.RemoveGithubId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :github_id
    end
  end
end
