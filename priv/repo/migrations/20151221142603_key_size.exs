defmodule Tmate.Repo.Migrations.KeySize do
  use Ecto.Migration

  def change do
    alter table(:identities) do
      modify :key,  :string, size: 4096, null: false
    end
  end
end
