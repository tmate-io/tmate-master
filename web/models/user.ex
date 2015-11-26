defmodule Tmate.User do
  use Ecto.Model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    field :email,               :string
    field :name,                :string
    field :nickname,            :string
    field :github_login,        :string
    field :github_access_token, :string
  end

  def changeset(model, params \\ :empty) do
    model
    |> change(params)
  end
end

