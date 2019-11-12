defmodule Tmate.Repo.Migrations.AddApiKey do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :api_key,            :string
      add :verified,           :boolean,     default: false
      add :allow_mailing_list, :boolean,     default: false
      add :created_at,         :utc_datetime
      add :last_seen_at,       :utc_datetime
    end

    create index(:users, [:api_key], [unique: true])
  end
end
