defmodule Tmate.Repo.Migrations.AddSshKeyHash do
  use Ecto.Migration

  def change do
    alter table(:identities) do
      add :hash, :string, null: false
    end
    create index(:identities, [:hash], [unique: true])
  end
end
