defmodule Tmate.PageView do
  use Tmate.Web, :view

  def global_vars(%{global_vars: global_vars}) do
    raw(Jason.encode!(global_vars))
  end

  def global_vars(_assigns) do
    raw("{}")
  end
end
