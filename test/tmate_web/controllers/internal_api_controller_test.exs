defmodule TmateWeb.InternalApiControllerTest do
  use TmateWeb.ConnCase
  import Tmate.EventCase

  test "webhook" do
    # test authentication
  end

  describe "/internal_api/session" do
    test "returns session" do
      session_event = build(:event_session_register)
      created_at = DateTime.utc_now
      emit_event(session_event, created_at)

      auth_token = "internal_api_auth_token"
      response =
        build_conn()
        |> put_req_header("authorization", "Bearer " <> auth_token)
        |> get("/internal_api/session", %{token: session_event.stoken})
        |> json_response(200)

      assert response == %{
        "id" => session_event.entity_id,
        "ssh_cmd_fmt" => session_event.ssh_cmd_fmt,
        "created_at" => created_at |> DateTime.truncate(:second) |> DateTime.to_iso8601,
        "disconnected_at" => nil,
        "closed" => false
      }
    end

    test "404 with unknown sessions" do
      auth_token = "internal_api_auth_token"
      build_conn()
      |> put_req_header("authorization", "Bearer " <> auth_token)
      |> get("/internal_api/session", %{token: "invalid_token"})
      |> json_response(404)
    end

    test "403 without the auth token" do
      auth_token = "invalid_auth_token"
      assert_error_sent 401, fn ->
        build_conn()
        |> put_req_header("authorization", "Bearer " <> auth_token)
        |> get("/internal_api/session", %{token: "invalid_token"})
      end
    end
  end
end
