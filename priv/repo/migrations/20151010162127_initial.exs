defmodule Tmate.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :host_identity_id, :integer, null: false
      add :host_last_ip,     :string,  null: false
      add :stoken,           :string,  size: 30,   null: false
      add :stoken_ro,        :string,  size: 30,   null: false
      add :closed_at,        :datetime
      timestamps
    end
    create index(:sessions, [:host_identity_id])
    create index(:sessions, [:stoken, :stoken_ro])

    create table(:ssh_identities) do
      add :user_id, :integer
      add :pubkey,  :string, size: 1024, null: false
      timestamps
    end
    create index(:ssh_identities, [:user_id])
    create index(:ssh_identities, [:pubkey], [unique: true])

    create table(:users) do
      add :anonymous, :boolean, null: false
      timestamps
    end
  end
end
