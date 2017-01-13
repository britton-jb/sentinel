defmodule Sentinel.Authenticator do
  @moduledoc """
  Handles Sentinel authentication logic
  """
  alias Sentinel.Config

  @doc """
  Compares user password and ensures user is confirmed if applicable
  """
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
  defp check_password(auth, password) do
    if Config.crypto_provider.checkpw(password, auth.hashed_password) do
      {:ok, auth}
    else
      {:error, %{base: @unknown_password_error_message}}
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
