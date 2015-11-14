defmodule Tmate.Session do
  use Ecto.Model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "sessions" do
    belongs_to :host_identity, Tmate.Identity
    field      :host_last_ip,  :string
    field      :ws_base_url,   :string
    field      :stoken,        :string
    field      :stoken_ro,     :string
    field      :created_at,    Ecto.DateTime
    field      :closed_at,     Ecto.DateTime
  end

  def changeset(model, params \\ :empty) do
    model
    |> change(params)
  end
end
