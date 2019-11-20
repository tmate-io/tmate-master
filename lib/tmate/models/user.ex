defmodule Tmate.User do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query
  alias Tmate.Repo
  alias Tmate.User

  require Logger

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "users" do
    field :username,     :string
    field :email,        :string
    field :api_key,      :string
    field :verified,     :boolean
    field :created_at,   :utc_datetime
    field :last_seen_at, :utc_datetime
    field :allow_mailing_list, :boolean
  end

  def get_by_api_key(api_key) do
    user = Repo.one(from u in User, where: u.api_key == ^api_key)
    if !user, do: :timer.sleep(:crypto.rand_uniform(50, 200))
    user
  end

  def repr(user) do
    "user=#{user.username} (#{user.email})"
  end

  def seen(user, timestamp) do
    Logger.info("#{User.repr(user)} seen")

    user
    |> change(%{verified: true, last_seen_at: timestamp})
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:username, :email, :allow_mailing_list])
    |> validate_required(:username)
    |> validate_length(:username, min: 1, max: 40)
    |> validate_format(:username, ~r/^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9]))*$/,
           message: "Username may only contain alphanumeric characters or single hyphens"
                     <> ", and cannot begin or end with a hyphen.")
    |> validate_required(:email)
    |> validate_format(:email, ~r/.@.*\.../, message: "Check your email")
    |> gen_api_key_if_empty()
    |> unique_constraint(:id, name: :users_pkey)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> unique_constraint(:api_key)
  end

  defmodule ApiKeyUtil do
    @api_key_letters "abcdefghjklmnopqrstuvwxyz" <>
                     "ABCDEFGHJKLMNOPQRSTUVWXYZ" <>
                     "0123456789"

    defp generate_random_char(chars, num_chars) do
      case :crypto.strong_rand_bytes(1) do
        <<rand_int>> when rand_int < num_chars -> String.at(chars, rand_int)
        _ -> generate_random_char(chars, num_chars)
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

  defp gen_api_key_if_empty(changeset) do
    case get_change(changeset, :api_key) do
      nil -> put_change(changeset, :api_key, ApiKeyUtil.gen_api_key())
      _ -> changeset
    end
  end
end
