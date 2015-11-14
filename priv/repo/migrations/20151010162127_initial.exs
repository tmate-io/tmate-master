defmodule Tmate.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :type,      :string,   null: false
      add :entity_id, :uuid,     null: false
      add :timestamp, :datetime, null: false
      add :params,    :map,      null: false
    end
    create index(:events, [:type])
    create index(:events, [:entity_id])

    create table(:sessions, primary_key: false) do
      add :id,               :uuid,    primary_key: true
      add :host_identity_id, :integer, null: false
      add :host_last_ip,     :string,  null: false
      add :ws_base_url,      :string,  null: false
      add :stoken,           :string,  size: 30, null: false
      add :stoken_ro,        :string,  size: 30, null: false
      add :created_at,       :datetime, null: false
      add :closed_at,        :datetime
    end
    create index(:sessions, [:host_identity_id])
    create index(:sessions, [:stoken])
    create index(:sessions, [:stoken_ro])

    create table(:identities) do
      add :user_id, :integer
      add :pubkey,  :string, size: 1024, null: false
    end
    create index(:identities, [:user_id])
    create index(:identities, [:pubkey], [unique: true])

    create table(:users, primary_key: false) do
      add :id,        :uuid,    primary_key: true, null: false
      add :anonymous, :boolean, null: false
    end
  end
end
