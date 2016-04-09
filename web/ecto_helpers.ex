defmodule Tmate.EctoHelpers do
  alias Tmate.Repo
  import Ecto.Query

  def get_or_insert(changeset, key, retry) when is_atom(key) do
    get_or_insert(changeset, [key], retry)
  end

  def get_or_insert(changeset, query_keys, retry) do
    params = Enum.map(query_keys, fn key ->
      {_, value} = Ecto.Changeset.fetch_field(changeset, key)
      {key, value}
    end) |> Enum.into(%{})

    case Repo.get_by(changeset.data.__struct__, params) do
      nil ->
        case {Repo.insert(changeset), retry} do
          {{:ok, instance}, _} ->
            {:ok, :insert, instance}
          {{:error, %{constraints: [%{field: _, type: :unique}]}}, true} ->
            # TODO write test case
            get_or_insert(changeset, query_keys, false)
          {{:error, changeset}, _} ->
            {:error, changeset}
        end
      instance -> {:ok, :get, instance}
    end
  end

  def get_or_insert(changeset, query_keys) do
    get_or_insert(changeset, query_keys, true)
  end

  def get_or_insert(changeset) do
    get_or_insert(changeset, Keyword.keys(Ecto.primary_key(changeset.data)))
  end

  def get_or_insert!(changeset, query_keys) do
    case get_or_insert(changeset, query_keys) do
      {:ok, _, instance} -> instance
      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
    end
  end

  def get_or_insert!(changeset) do
    get_or_insert!(changeset, Keyword.keys(Ecto.primary_key(changeset.data)))
  end

  def last(model) do
    Repo.one(from s in model, order_by: [desc: :id], limit: 1)
  end

  def validate_changeset(changeset) do
    # TODO ecto won't do uniqueness validations unless all the other validations
    # went through. This is a litte sad.
    case Repo.transaction(fn ->
      result = changeset |> Repo.insert
      Repo.rollback({:insert_result, result})
    end) do
      {:error, {:insert_result, {:ok, _}}} -> :ok
      {:error, {:insert_result, {:error, changeset}}} -> {:error, changeset}
    end
  end
end
