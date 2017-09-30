defmodule Sentinel.Changeset.Confirmator do
  alias Ecto.Changeset
  alias Sentinel.Config

  @moduledoc """
  Handles confirmation logic, including whether confirmation is needed, and the
  confirmation changeset
  """

  @doc """
  Adds the changes needed for a user's email confirmation to the given changeset.
  Returns {unhashed_confirmation_token, changeset}
  """
  def confirmation_needed_changeset(changeset) do
    {confirmation_token, hashed_confirmation_token} = generate_token()

    changeset =
      changeset
      |> Changeset.put_change(:confirmed_at, nil)
      |> Changeset.put_change(:hashed_confirmation_token, hashed_confirmation_token)

    {confirmation_token, changeset}
  end

  # Generates a random token.
  # Returns {token, hashed_token}.
  defp generate_token do
    token = SecureRandom.urlsafe_base64()
    {token, Config.crypto_provider.hashpwsalt(token)}
  end

  @doc """
  Returns a changeset which, when applied, confirms the user.
  If params["confirmation_token"] does not match, an error is added
  to the changeset.
  """
  def confirmation_changeset(%{confirmed_at: nil} = user, params) do
    user
    |> Changeset.cast(params, [])
    |> successfully_confirm
    |> validate_token
  end
  def confirmation_changeset(%{unconfirmed_email: unconfirmed_email} = user, params) when unconfirmed_email != nil do
    user
    |> Changeset.cast(params, [])
    |> successfully_confirm
    |> Changeset.put_change(:email, unconfirmed_email)
    |> validate_token
  end
  def confirmation_changeset(%{data: %{unconfirmed_email: unconfirmed_email}} = changeset) when unconfirmed_email != nil and unconfirmed_email != "" do
    changeset
    |> Changeset.put_change(:email, unconfirmed_email)
    |> validate_token
    |> successfully_confirm
  end
  def confirmation_changeset(%{data: %{confirmed_at: nil}} = password_reset_changeset) do
    password_reset_changeset
    |> validate_token
    |> successfully_confirm
  end

  defp successfully_confirm(changeset) do
    changeset
    |> Changeset.put_change(:unconfirmed_email, nil)
    |> Changeset.put_change(:hashed_confirmation_token, nil)
    |> Changeset.put_change(:confirmed_at, DateTime.utc_now)
  end

  defp validate_token(changeset) do
    token_matches = Config.crypto_provider.checkpw(changeset.params["confirmation_token"],
    changeset.data.hashed_confirmation_token)
    do_validate_token token_matches, changeset
  end

  defp do_validate_token(true, changeset), do: changeset
  defp do_validate_token(false, changeset) do
    Changeset.add_error(changeset, :confirmation_token, "invalid")
  end
end
