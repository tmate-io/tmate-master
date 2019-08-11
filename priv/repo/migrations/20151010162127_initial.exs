defmodule Tmate.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :type,      :string,   null: false
      add :entity_id, :uuid
      add :timestamp, :utc_datetime, null: false
      add :params,    :map,      null: false
    end
    create index(:events, [:type])
    create index(:events, [:entity_id])

    create table(:identities) do
      add :type, :string, null: false
      add :key,  :string, size: 1024, null: false
    end
    create index(:identities, [:type, :key], [unique: true])

    create table(:sessions, primary_key: false) do
      add :id,               :uuid,    primary_key: true
      add :host_identity_id, references(:identities, type: :integer), null: false
      add :host_last_ip,     :string,  null: false
      add :ws_base_url,      :string,  null: false
      add :stoken,           :string,  size: 30, null: false
      add :stoken_ro,        :string,  size: 30, null: false
      add :created_at,       :utc_datetime, null: false
      add :closed_at,        :utc_datetime
    end
    create index(:sessions, [:host_identity_id])
    create index(:sessions, [:stoken])
    create index(:sessions, [:stoken_ro])

    create table(:clients, primary_key: false) do
      add :session_id,  references(:sessions, type: :uuid, on_delete: :delete_all), null: false
      add :identity_id, references(:identities, type: :integer), null: false
      add :client_id,   :integer,  null: false
      add :ip_address,  :string,   null: false
      add :joined_at,   :utc_datetime, null: false
      add :readonly,    :boolean,  null: false
    end
    create index(:clients, [:session_id, :client_id], [unique: true])
    create index(:clients, [:session_id])
    create index(:clients, [:client_id])

    create table(:users, primary_key: false) do
      add :id,                  :uuid,   primary_key: true
      add :email,               :string, null: false
      add :name,                :string, null: false
      add :nickname,            :string, null: false
      add :github_login,        :string
      add :github_access_token, :string
    end
  end
end
