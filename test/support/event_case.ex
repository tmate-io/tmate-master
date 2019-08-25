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
      import Ecto.Model, except: [build: 2]
      import Ecto.Query, only: [from: 2]
      import Tmate.EventCase
      import Tmate.Factory
    end
  end

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
    {:ok, pid} = Tmate.Websocket.Endpoint.start_link
    :ok = Ecto.Adapters.SQL.Sandbox.allow(Tmate.Repo, self(), pid)
    {:ok, %{websocket_endpoint: pid}}
  end

  def emit_event(context, event) do
    {m, params} = Map.split(event, [:event_type, :entity_id])
    emit_raw_event(context, m[:event_type], m[:entity_id], params)
    event
  end

  def emit_raw_event(%{websocket_endpoint: pid}, event_type, entity_id, params) do
    timestamp = current_timestamp()
    {:reply, :ok} = Tmate.Websocket.Endpoint.call(pid,
                     {:event, timestamp, event_type, entity_id, params})
  end

  defp current_timestamp() do
    # from Ecto lib.
    erl_timestamp = :os.timestamp
    {_, _, usec} = erl_timestamp
    {date, {h, m, s}} = :calendar.now_to_datetime(erl_timestamp)
    {date, {h, m, s, usec}}
  end
end
