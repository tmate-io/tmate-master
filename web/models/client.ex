defmodule Tmate.Client do
  use Tmate.Web, :model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "clients" do
    belongs_to :session,  Tmate.Session, type: :binary_id, references: :id
    field :ip_address,    :string
    field :joined_at,     :utc_datetime
    field :left_at,       :utc_datetime
    field :readonly,      :boolean
    field :latency_stats, :map
    belongs_to :identity, Tmate.Identity, references: :id
  end

  def changeset(model, params \\ %{}) do
    model
    |> change(params)
    |> unique_constraint(:id, name: :clients_pkey)
  end
end
