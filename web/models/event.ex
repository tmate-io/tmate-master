defmodule Tmate.Event do
  use Ecto.Model

  @primary_key false

  schema "events" do
    field :type,      :string
    field :entity_id, Ecto.UUID
    field :timestamp, Ecto.DateTime
    field :params,    :map
  end

  def changeset(model, params \\ :empty) do
    model
    |> change(params)
  end
end
