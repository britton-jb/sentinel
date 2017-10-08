defmodule Sentinel.Mailer.Invite do
  @moduledoc """
  Responsible for the creation (and easy override) of the default invitation
  email
  """

  import Bamboo.Email
  import Bamboo.Phoenix
  import Sentinel.Mailer

  @doc """
  Takes a user, and a map containing a confirmation token & password reset
  token and returns an email. It does not send the email
  """
  def build(user, %{confirmation_token: confirmation_token, password_reset_token: password_reset_token}) do
    user
    |> base_email
    |> assign(:user, user)
    |> assign(:confirmation_token, confirmation_token)
    |> assign(:password_reset_token, password_reset_token)
    |> subject("You've been invited to #{app_name()} #{user.email}")
    |> render(:invite)
  end
end
