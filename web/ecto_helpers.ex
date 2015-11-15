defmodule Tmate.EctoHelpers do
  alias Tmate.Repo
  import Ecto.Query

  def get_or_create(model, params, create_params, retry) do
    case Repo.get_by(model, params) do
      nil ->
        new_params = Map.merge(create_params, params |> Enum.into(%{}))
        case {model.changeset(model.__struct__, new_params) |> Repo.insert, retry} do
          {{:ok, instance}, _} -> {:ok, instance}
          {{:error, %{constraints: [%{field: _, type: :unique}]}}, true} ->
            get_or_create(model, params, create_params)
          {{:error, changeset}, _} -> {:error, changeset}
        end
      instance -> {:ok, instance}
    end
  end

  def get_or_create(model, params, create_params \\ %{}) do
    get_or_create(model, params, create_params, true)
  end

  def get_or_create!(model, params, create_params \\ %{}) do
    case get_or_create(model, params, create_params) do
      {:ok, instance} -> instance
      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
    end
  end

  def last(model) do
    Repo.one(from s in model, order_by: [desc: :id], limit: 1)
  end
end
