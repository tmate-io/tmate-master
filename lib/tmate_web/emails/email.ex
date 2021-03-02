defmodule Tmate.Email do
  use Bamboo.Phoenix, view: TmateWeb.EmailView

  def api_key_email(%{email: email, username: username, api_key: api_key}) do
    base_email()
    |> to(email)
    |> subject("Your tmate API key")
    |> assign(:api_key, api_key)
    |> assign(:username, username)
    |> render(:api_key)
  end

  defp base_email do
    new_email()
    |> from(Application.fetch_env!(:tmate, Tmate.Mailer)[:from])
    |> put_html_layout({TmateWeb.LayoutView, "email.html"})
  end
end
