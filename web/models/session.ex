defmodule Tmate.Session do
  use Ecto.Model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "sessions" do
    belongs_to :host_identity, Tmate.Identity
    field      :host_last_ip,  :string
    field      :host_latency_stats, :map
    field      :ws_url_fmt,    :string
    field      :ssh_cmd_fmt,   :string
    field      :stoken,        :string
    field      :stoken_ro,     :string
    field      :created_at,    Ecto.DateTime
    field      :closed_at,     Ecto.DateTime

    has_many   :clients,       Tmate.Client
  end

  def changeset(model, params \\ %{}) do
    model
    |> change(params)
  end
end
