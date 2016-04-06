defmodule Tmate.User do
  use Tmate.Web, :model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    field :email,               :string
    field :name,                :string
    field :username,            :string
    field :github_login,        :string
    field :github_access_token, :string
  end

  def changeset(model, params \\ %{}) do
    model
    |> change(params)
  end
end

