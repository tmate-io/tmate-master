defmodule Tmate.Repo.Migrations.ExpandTokenSize do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      modify :stoken,    :string, size: 255
      modify :stoken_ro, :string, size: 255
    end
  end
end
