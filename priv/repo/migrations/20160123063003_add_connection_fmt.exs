defmodule Tmate.Repo.Migrations.AddConnectionFmt do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      remove :ws_base_url
      add :ws_url_fmt, :string
      add :ssh_cmd_fmt, :string
    end
  end
end
