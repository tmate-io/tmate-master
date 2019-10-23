defmodule Tmate.WsApi do
  def internal_api_opts do
    # XXX We can't pass the auth token directly, it is not
    # necessarily defined at compile time.
    Application.fetch_env!(:tmate, :master)[:internal_api]
  end
  use Tmate.Util.JsonApi, fn_opts: &__MODULE__.internal_api_opts/0

  def get_stale_sessions(session_ids, base_url) do
    case post(base_url <> "/get_stale_sessions", %{session_ids: session_ids}) do
      {:ok, body} -> {:ok, body["stale_ids"]}
      {:error, reason} -> {:error, reason}
    end
  end
end
