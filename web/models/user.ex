defmodule Tmate.User do
  use Tmate.Web, :model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    field :username,  :string
    field :email,     :string
    field :github_id, :integer
  end

  def changeset(model, params) do
    model
    |> cast(params, ~w(username email), ~w(github_id))
    |> validate_length(:username, min: 1, max: 40)
    |> validate_format(:username, ~r/^((?![A-Z]).)*$/, message: "may only be in lowercase")
    |> validate_format(:username, ~r/^[a-z0-9_]*$/, message: "may only contain lowercase alphanumeric characters and '_'")
    |> validate_format(:email, ~r/.@.*\.../)
    |> unique_constraint(:id, name: :users_pkey)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> unique_constraint(:github_id)
  end
end
