defmodule Tmate.Repo.Migrations.ExpandTokenSize do
  use Ecto.Migration

  def change do
    drop index(:sessions, [:stoken])
    drop index(:sessions, [:stoken_ro])

    flush()

    alter table(:sessions) do
      modify :stoken,    :string, size: 255
      modify :stoken_ro, :string, size: 255
    end

    create index(:sessions, [:stoken])
    create index(:sessions, [:stoken_ro])
  end
end
