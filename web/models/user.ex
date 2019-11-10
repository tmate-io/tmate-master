defmodule Tmate.User do
  use Tmate.Web, :model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    field :username,  :string
    field :email,     :string
  end

  def changeset(model, params) do
    model
    |> cast(params, [:uername, :email])
    |> validate_length(:username, min: 1, max: 40)
    |> validate_format(:username, ~r/^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9]))*$/,
           message: "Username may only contain alphanumeric characters or single hyphens"
                     <> ", and cannot begin or end with a hyphen.")
    |> validate_format(:email, ~r/.@.*\.../)
    |> unique_constraint(:id, name: :users_pkey)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end
end
