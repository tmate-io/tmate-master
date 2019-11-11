defmodule Tmate.EventCase do
  @moduledoc """
  This module defines the test case to be used by
  model tests.

  You may define functions here to be used as helpers in
  your model tests. See `errors_on/2`'s definition as reference.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Tmate.Repo
      import Ecto.Query
      import Tmate.EventCase
      import Tmate.Factory
    end
  end


  # Import conveniences for testing with connections
  use Phoenix.ConnTest
  # The default endpoint for testing
  @endpoint Tmate.Endpoint

  @doc """
  Helper for returning list of errors in model when passed certain data.

  ## Examples

  Given a User model that lists `:name` as a required field and validates
  `:password` to be safe, it would return:

      iex> errors_on(%User{}, password: "password")
      [password: "is unsafe", name: "is blank"]

  You could then write your assertion like:

      assert {:password, "is unsafe"} in errors_on(%User{}, password: "password")

  You can also create the changeset manually and retrieve the errors
  field directly:

      iex> changeset = User.changeset(%User{}, password: "password")
      iex> {:password, "is unsafe"} in changeset.errors
      true
  """
  def errors_on(model, data) do
    model.__struct__.changeset(model, data).errors
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Tmate.Repo)
    # {:ok, pid} = Tmate.Websocket.Endpoint.start_link
    # :ok = Ecto.Adapters.SQL.Sandbox.allow(Tmate.Repo, self(), self())
    {:ok, %{}}
  end

  def emit_event(event, timestamp \\ DateTime.utc_now) do
    {m, params} = Map.split(event, [:event_type, :entity_id, :generation])
    generation = m[:generation] || 1
    emit_raw_event(m[:event_type], m[:entity_id], timestamp, generation, params)
    event
  end

  def emit_raw_event(event_type, entity_id, timestamp, generation, params) do
    auth_token = "internal_api_auth_token"
    payload = Jason.encode!(%{type: event_type, entity_id: entity_id, timestamp: timestamp,
                              generation: generation, userdata: auth_token, params: params})

    build_conn()
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json")
    # |> put_req_header("authorization", "Bearer " <> auth_token)
    |> post("/internal_api/webhook", payload)
    |> json_response(200)
  end
end
