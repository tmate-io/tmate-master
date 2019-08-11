defmodule Tmate.Event do
  use Tmate.Web, :model

  schema "events" do
    field :type,      :string
    field :entity_id, Ecto.UUID
    field :timestamp, :utc_datetime
    field :params,    :map
  end

  def changeset(model, params \\ %{}) do
    model
    |> change(params)
  end

  def emit!(event_type, entity_id, params) do
    now = DateTime.utc_now
    emit!(event_type, entity_id, now, params)
  end

  def emit!(event_type, entity_id, ecto_timestamp, params) do
    # TODO GenEvent?
    args = [event_type, entity_id, ecto_timestamp, params]
    [__MODULE__.Projection,
     __MODULE__.Store,
     __MODULE__.Broadcast]
    |> Enum.each(&apply(&1, :handle_event, args))
  end
end
