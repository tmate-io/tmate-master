defmodule Tmate.Repo.Migrations.RemoveIdentityOne do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      modify :host_identity_id, :integer, null: true
    end

    drop constraint(:sessions, "sessions_host_identity_id_fkey")

    alter table(:clients) do
      modify :identity_id, :integer, null: true
    end

    drop constraint(:clients, "clients_identity_id_fkey")
  end
end
