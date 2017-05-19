defmodule Sentinel.Authenticator do
  @moduledoc """
  Handles Sentinel authentication logic
  """
  alias Sentinel.Config

  @locked_account_message "This account is currently locked. Please follow the instructions in your email to unlock it."

  @doc """
  Compares user password and ensures user is confirmed if applicable
  """
  def authenticate(%Sentinel.Ueberauth{locked_at: locked_at}, _password) when not is_nil(locked_at) do
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
  defp check_password(auth, password) do
    case {Config.crypto_provider.checkpw(password, auth.hashed_password), Config.lockable?, auth} do
      {true, _, _} -> {:ok, auth}
      {false, true, %Sentinel.Ueberauth{failed_attempts: 3}} ->
        Sentinel.Ueberauth.increment_failed_attempts(auth)
        {:error, %{base: "You have one more attempt to authenticate correctly before this account is locked."}}
      {false, true, %Sentinel.Ueberauth{failed_attempts: 4}} ->
        Sentinel.Ueberauth.lock(auth)
        {:error, %{base: "This account has been locked, due to too many failed login attempts."}}
      {false, true, _} ->
        Sentinel.Ueberauth.increment_failed_attempts(auth)
        {:error, %{base: @unknown_password_error_message}}
      {_, _, _} ->
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
