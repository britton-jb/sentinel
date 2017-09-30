defmodule Sentinel.Changeset.PasswordResetter do
  @moduledoc """
  Module responsible for handling the password reset logic changeset
  """
  alias Ecto.Changeset
  alias Sentinel.{Changeset.HashPassword, Config}

  @doc """
  Adds the changes needed to create a password reset token.
  Returns {unhashed_password_reset_token, changeset}
  """
  def create_changeset(%Sentinel.Ueberauth{provider: "identity"} = auth) do
    {password_reset_token, hashed_password_reset_token} = generate_token()

    changeset =
      auth
      |> Changeset.cast(%{}, [])
      |> Changeset.put_change(:hashed_password_reset_token, hashed_password_reset_token)

    {password_reset_token, changeset}
  end
  def create_changeset(_auth) do
    changeset =
      %Sentinel.Ueberauth{}
      |> Changeset.cast(%{}, [])
      |> Changeset.add_error(:email, "not known")
    {nil, changeset}
  end

  @doc """
  Changes a user's identity ueberauth password, if the reset token matches.
  Params should be Ueberauth.Auth struct
  Returns the changeset
  """
  def reset_changeset(%Sentinel.Ueberauth{provider: "identity"} = auth, params) do
    auth
    |> Changeset.cast(params, [])
    |> Changeset.put_change(:hashed_password_reset_token, nil)
    |> validate_token
    |> validate_password_and_confirmation_match
    |> HashPassword.changeset(params)
  end
  def reset_changeset(_auth, _params) do
    %Sentinel.Ueberauth{}
    |> Changeset.cast(%{}, [])
    |> Changeset.add_error(:uid, "unknown")
  end

  @doc """
  Generates a random token.
  Returns {token, hashed_token}.
  """
  def generate_token do
    token = SecureRandom.urlsafe_base64()
    {token, Config.crypto_provider.hashpwsalt(token)}
  end

  defp validate_token(%{params: %{"password_reset_token" => password_reset_token}} = changeset) do
    token_matches = Config.crypto_provider.checkpw(
      password_reset_token,
      changeset.data.hashed_password_reset_token
    )
    do_validate_token(token_matches, changeset)
  end

  defp do_validate_token(true, changeset), do: changeset
  defp do_validate_token(false, changeset) do
    Changeset.add_error changeset, :password_reset_token, "invalid"
  end

  defp validate_password_and_confirmation_match(%{params: %{"credentials" => %{other: %{password: password, password_confirmation: password}}}} = changeset) do
    changeset
  end
  defp validate_password_and_confirmation_match(changeset) do
    Changeset.add_error changeset, :password_confirmation, "mismatch"
  end
end
