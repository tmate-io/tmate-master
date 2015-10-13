defmodule Tmate.EctoHelpers do
  alias Tmate.Repo
  import Ecto.Query

  def get_or_create(model, params=[{key, value}], create_params \\ %{}) do
    case Repo.get_by(model, params) do
      nil ->
        new_params = Map.put(create_params, key, value)
        case model.changeset(model.__struct__, new_params) |> Repo.insert do
          {:ok, instance} -> {:ok, instance}
          {:error, %{constraints: [%{field: ^key, type: :unique}]}} ->
            get_or_create(model, params, create_params)
          {:error, changeset} -> {:error, changeset}
        end
      instance -> {:ok, instance}
    end
  end

  def get_or_create!(model, params, create_params \\ %{}) do
    case get_or_create(model, params) do
      {:ok, instance} -> instance
      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
    end
  end

  def last(model) do
    Repo.one(from s in model, order_by: [desc: :id], limit: 1)
  end
end
