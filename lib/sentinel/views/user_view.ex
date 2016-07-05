defmodule Sentinel.UserView do
  use Phoenix.View, root: "lib/sentinel/templates/"
  use Phoenix.HTML

  def render("index.json", %{users: users}) do
    render_many(users, Sentinel.UserView, "user.json")
  end

  def render("show.json", %{user: user}) do
    render_one(user, Sentinel.UserView, "user.json")
  end

  def render("user.json", %{user: user}) do
    %{id: user.id,
      email: user.email,
      role: user.role,
      hashed_password: user.hashed_password,
      hashed_confirmation_token: user.hashed_confirmation_token,
      confirmed_at: user.confirmed_at,
      hashed_password_reset_token: user.hashed_password_reset_token,
      unconfirmed_email: user.unconfirmed_email}
  end
end
