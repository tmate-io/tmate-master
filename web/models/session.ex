defmodule Tmate.Session do
  use Ecto.Model

  schema "sessions" do
    belongs_to :host_identity, Tmate.SSHIdentity
    field      :host_last_ip,  :string
    field      :stoken,        :string
    field      :stoken_ro,     :string
    field      :closed_at,     Ecto.DateTime
    timestamps
  end

  def changeset(session, params \\ :empty) do
    session
    |> cast(params, [:host_identity_id, :host_last_ip, :stoken, :stoken_ro])
  end
end
