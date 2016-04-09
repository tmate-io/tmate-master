defmodule Tmate.ChangesetView do
  use Tmate.Web, :view

  def render("error.json", %{changeset: changeset}) do
    validation_errors = Enum.reduce(changeset.errors, %{}, fn {field, error}, errors ->
      Map.merge(errors, %{field => render_changeset_error(error)})
    end)

    if Enum.empty?(validation_errors) do
      raise "No validation errors for #{inspect(changeset)}"
    end

    %{validation_errors: validation_errors}
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
