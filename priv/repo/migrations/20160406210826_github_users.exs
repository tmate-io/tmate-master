defmodule Tmate.Repo.Migrations.GithubUsers do
  use Ecto.Migration

  def change do
    rename table(:users), :nickname, to: :username
    alter table(:users) do
      remove :github_access_token
      remove :github_login
      remove :name
      add :github_id, :integer
    end
    create index(:users, [:username], unique: true)
    create index(:users, [:email], unique: true)
    create index(:users, [:github_id], unique: true, where: "github_id is not null")
  end
end
