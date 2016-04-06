defmodule Tmate.Factory do
  use ExMachina

  def factory(:event_session_register) do
    %{event_type: :session_register,
      entity_id: UUID.uuid1,
      ip_address: sequence(:ip, &"1.1.1.#{&1}"),
      pubkey: sequence(:pubkey, & Base.encode64("pubkey#{&1}")),
      ws_url_fmt: "https://tmate.io/ws/session/%s",
      ssh_cmd_fmt: "ssh %s@tmate.io",
      stoken: sequence(:token, &"STOKEN___________________RW#{&1}"),
      stoken_ro: sequence(:token, &"STOKEN___________________RO#{&1}")}
  end

  def factory(:event_session_close) do
    %{event_type: :session_close,
      entity_id: UUID.uuid1}
  end

  def factory(:event_session_join) do
    %{event_type: :session_join,
      id: UUID.uuid1,
      ip_address: sequence(:ip, &"1.1.2.#{&1}"),
      type: "ssh",
      identity: sequence(:pubkey, & Base.encode64("pubkey#{&1}")),
      readonly: false}
  end

  def factory(:event_session_left) do
    %{event_type: :session_left,
      id: sequence(:client_id, & &1)}
  end
end
