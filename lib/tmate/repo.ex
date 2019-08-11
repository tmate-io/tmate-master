defmodule Tmate.Repo do
  use Ecto.Repo,
      otp_app: :tmate,
      adapter: Ecto.Adapters.Postgres
end
