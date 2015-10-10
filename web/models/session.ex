defmodule Tmate.Session do
  use Ecto.Model

  schema "sessions" do
    belongs_to :host_identity, SSHIdentity
    field      :host_last_ip,  :string
    field      :stoken,        :string
    field      :stoken_ro,     :string
    field      :active,        :boolean
    timestamps
  end
end
