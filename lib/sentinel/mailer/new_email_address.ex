defmodule Sentinel.Mailer.NewEmailAddress do
  @moduledoc """
  Responsible for the creation (and easy override) of the default new email
  address email
  """

  import Bamboo.Email
  import Bamboo.Phoenix
  import Sentinel.Mailer

  @doc """
  Takes a user, and a confirmation token & returns an email. It does not send
  the email
  """
  def build(user, confirmation_token) do
    user
    |> base_email
    |> to(user)
    |> subject("Please confirm your email address")
    |> assign(:user, user)
    |> assign(:confirmation_token, confirmation_token)
    |> render(:new_email_address)
  end
end
