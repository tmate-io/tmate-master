defmodule TmateWeb.TerminalView do
  use TmateWeb, :view

  def title("show.html", %{token: token}) do
    "tmate • #{token}"
  end
end
