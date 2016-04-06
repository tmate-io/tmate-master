defmodule Tmate.ChangesetView do
  use Tmate.Web, :view

  def render("error.json", %{changeset: changeset}) do
    errors = Enum.map(changeset.errors, fn {field, error} ->
      %{type: :field_validation_error, field: field, error: render_changeset_error(error) }
    end)

    %{errors: errors}
  end

  def render_changeset_error({message, values}) do
    Enum.reduce values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  def render_changeset_error(message) do
    message
  end
end
