{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start
Mix.Task.run "ecto.create", ["--quiet"]
Mix.Task.run "ecto.migrate", ["--quiet"]
Ecto.Adapters.SQL.Sandbox.mode(Tmate.Repo, :manual)
