defmodule Sentinel.Mailer.PasswordReset do
  @moduledoc """
  Responsible for the creation (and easy override) of the default password
  reset email
  """

  import Bamboo.Email
  import Bamboo.Phoenix
  import Sentinel.Mailer

  @doc """
  Takes a user, and a confirmation token and returns an email. It does not send
  the email
  """
  def build(user, password_reset_token) do
    user
    |> base_email
    |> assign(:user, user)
    |> assign(:password_reset_token, password_reset_token)
    |> subject("Reset Your Password")
    |> render(:password_reset)
  end
end
