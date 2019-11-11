defmodule Tmate.User do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query
  alias Tmate.Repo
  alias Tmate.User

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    field :username,     :string
    field :email,        :string
    field :api_key,      :string
    field :verified,     :boolean
    field :created_at,   :utc_datetime
    field :last_seen_at, :utc_datetime
  end

  def get_by_api_key(api_key) do
    user = Repo.one(from u in User, where: u.api_key == ^api_key)
    if !user, do: :timer.sleep(:crypto.rand_uniform(50, 200))
    user
  end

  defmodule CreateUtil do
    @api_key_letters "abcdefghjklmnopqrstuvwxyz" <>
                     "ABCDEFGHJKLMNOPQRSTUVWXYZ" <>
                     "0123456789"

    defp generate_random_char(chars, num_chars) do
      <<rand_int>> = :crypto.strong_rand_bytes(1)
      if rand_int < num_chars do
        String.at(chars, rand_int)
      else
        generate_random_char(chars, num_chars)
      end
    end

    defp generate_random_string(chars, length) do
      rand_char = fn -> generate_random_char(chars, String.length(chars)) end
      Stream.repeatedly(rand_char) |> Enum.take(length) |> Enum.join()
    end

    def gen_api_key() do
      "tmk-#{generate_random_string(@api_key_letters, 26)}"
    end
  end

  def create(username, email) do
    api_key = CreateUtil.gen_api_key()

    %User{}
    |> changeset(%{username: username, email: email, api_key: api_key})
    |> Repo.insert
  end

  def changeset(model, params) do
    model
    |> cast(params, [:username, :email, :api_key])
    |> validate_length(:username, min: 1, max: 40)
    |> validate_format(:username, ~r/^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9]))*$/,
           message: "Username may only contain alphanumeric characters or single hyphens"
                     <> ", and cannot begin or end with a hyphen.")
    |> validate_format(:email, ~r/.@.*\.../)
    |> unique_constraint(:id, name: :users_pkey)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> unique_constraint(:api_key)
  end
end
