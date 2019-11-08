defmodule Tmate.Repo.Migrations.RemoveIdentityThree do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      remove :host_identity_id
    end

    alter table(:clients) do
      remove :identity_id
    end

    drop table(:identities)
  end
end
