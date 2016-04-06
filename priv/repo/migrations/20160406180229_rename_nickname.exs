defmodule Tmate.Repo.Migrations.RenameNickname do
  use Ecto.Migration

  def change do
    rename table(:users), :nickname, to: :username
  end
end
