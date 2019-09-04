defmodule Tmate.Session do
  use Tmate.Web, :model

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "sessions" do
    belongs_to :host_identity,      Tmate.Identity
    field      :host_last_ip,       :string
    field      :ws_url_fmt,         :string
    field      :ssh_cmd_fmt,        :string
    field      :stoken,             :string
    field      :stoken_ro,          :string
    field      :created_at,         :utc_datetime
    field      :disconnected_at,    :utc_datetime
    has_many   :clients,            Tmate.Client
  end

  def changeset(model, params \\ %{}) do
    model
    |> change(params)
    |> unique_constraint(:id, name: :sessions_pkey)
  end

  def edge_srv_hostname(ssh_hostname) do
    # ssh -p2200 %s@ny3.tmate.io
    ssh_hostname
    |> String.split("@") |> Enum.at(1)
    |> String.split(".") |> Enum.at(0)
  end
end
