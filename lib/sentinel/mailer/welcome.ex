defmodule Sentinel.Mailer.Welcome do
  @moduledoc """
  Responsible for the creation (and easy override) of the default welcome email
  """

  import Bamboo.Email
  import Bamboo.Phoenix
  import Sentinel.Mailer

  @doc """
  Takes a user, and a confirmation token and returns an email. It does not send
  the email
  """
  def build(user, confirmation_token) do
    user
    |> base_email
    |> assign(:user, user)
    |> assign(:confirmation_token, confirmation_token)
    |> subject("Hello #{user.email}")
    |> render(:welcome)
  end
end
