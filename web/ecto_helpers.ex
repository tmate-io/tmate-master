defmodule Tmate.EctoHelpers do
  alias Tmate.Repo
  import Ecto.Query

  def get_or_create(changeset, key, retry) when is_atom(key) do
    get_or_create(changeset, [key], retry)
  end

  def get_or_create(changeset, query_keys, retry) do
    params = Enum.map(query_keys, fn key ->
      {_, value} = Ecto.Changeset.fetch_field(changeset, key)
      {key, value}
    end) |> Enum.into(%{})

    case Repo.get_by(changeset.data.__struct__, params) do
      nil ->
        case {Repo.insert(changeset), retry} do
          {{:ok, instance}, _} -> {:ok, instance}
          {{:error, %{constraints: [%{field: _, type: :unique}]}}, true} ->
            get_or_create(changeset, query_keys, false)
          {{:error, changeset}, _} -> {:error, changeset}
        end
      instance -> {:ok, instance}
    end
  end

  def get_or_create(changeset, query_keys) do
    get_or_create(changeset, query_keys, true)
  end

  def get_or_create!(changeset, query_keys) do
    case get_or_create(changeset, query_keys) do
      {:ok, instance} -> instance
      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
    end
  end

  def get_or_create!(changeset) do
    get_or_create(changeset, Keyword.keys(Ecto.Model.primary_key(changeset.data)))
  end

  def last(model) do
    Repo.one(from s in model, order_by: [desc: :id], limit: 1)
  end
end
