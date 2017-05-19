defmodule Sentinel.Authenticator do
  @moduledoc """
  Handles Sentinel authentication logic
  """
  alias Sentinel.Config

  @locked_account_message "This account is currently locked. Please follow the instructions in your email to unlock it."
  @doc """
  Compares user password and ensures user is confirmed if applicable
  """
  def authenticate(%Sentinel.Ueberauth{locked_at: locked_at}) when not is_nil(locked_at) do
    # FIXME add spec here
    {:error, %{base: @locked_account_message}}
  end
  def authenticate(auth, password) do
    case check_password(auth, password) do
      {:ok, %Sentinel.Ueberauth{user: %{confirmed_at: nil}}} -> auth.user |> confirmation_required?
      {:ok, _} -> {:ok, auth.user}
      error -> error
    end
  end

  @unknown_password_error_message "Unknown email or password"
  defp check_password(nil, _) do
    Config.crypto_provider.dummy_checkpw
    {:error, %{base: @unknown_password_error_message}}
  end
  defp check_password(%Sentinel.Ueberauth{locked_at: locked_at}) when not is_nil(locked_at) do
    {:error, %{base: @locked_account_message}}
  end
  defp check_password(auth, password) do
    if Config.crypto_provider.checkpw(password, auth.hashed_password) do
      {:ok, auth}
    else
      # FIXME - right here I need to increment the lock count if lockable is configured
      if Config.lockable? do
        failed_attempts = auth.failed_attempts + 1

       #update_params =
       #   if failed_attempts >= 5 do
       #     %{}
       #   else
       #   end
       # updated_auth = 
       #   auth
       #   |> Sentinel.Ueberauth.changeset(update_params)
       #   |> Sentinel.Config.repo.update()


#FIXME send error if 3 failed
      else
        {:error, %{base: @unknown_password_error_message}}
      end
    end
  end

  defp confirmation_required?(user) do
    case Config.confirmable do
      :required ->
        {:error, %{base: "Account not confirmed yet. Please follow the instructions we sent you by email."}}
      _ ->
        {:ok, user}
    end
  end
end
