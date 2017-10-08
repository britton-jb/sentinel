defmodule Sentinel.Mailer.Unlock do
  @moduledoc """
  Responsible for the creation (and easy override) of the default unlock
  email
  """

  import Bamboo.Email
  import Bamboo.Phoenix
  import Sentinel.Mailer

  @doc """
  Takes a user, and a map containing the unlo
  token and returns an email. It does not send the email
  """
  @spec build(struct, String.t()) :: map
  def build(user, unlock_token) do
    user
    |> base_email
    |> assign(:user, user)
    |> assign(:unlock_token, unlock_token)
    |> subject("Unlock your #{app_name()} account")
    |> render(:unlock)
  end
end
