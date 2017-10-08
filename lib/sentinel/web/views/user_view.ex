defmodule Sentinel.UserView do
  use Phoenix.View, root: "lib/sentinel/web/templates/"
  use Phoenix.HTML

  alias Sentinel.Config

  def render("index.json", %{users: users}) do
    render_many(users, user_view(), "user.json")
  end

  def render("show.json", %{user: user, token: token}) do
    %{data: %{token: token, user: render_one(user, user_view(), "user.json")}}
  end
  def render("show.json", %{user: user}) do
    render_one(user, user_view(), "user.json")
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      email: user.email,
      hashed_confirmation_token: user.hashed_confirmation_token,
      confirmed_at: user.confirmed_at,
      unconfirmed_email: user.unconfirmed_email}
  end

  defp user_view do
    Config.views.user
  end
end
