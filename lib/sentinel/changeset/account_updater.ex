defmodule Sentinel.Changeset.AccountUpdater do
  @moduledoc """
  Handles account update functionality, including new emaili confirmation
  """

  alias Ecto.Changeset
  alias Sentinel.{Changeset.HashPassword, Changeset.Confirmator, Config}

  @doc """
  Returns confirmation token and changeset updating email and hashed_password on an existing user.
  Validates that email and password are present and that email is unique.
  """
  def changeset(user, params) do
    user
    |> Changeset.cast(params, [])
    |> Sentinel.Helpers.InjectedChangesetHelper.apply(Config.user_model_validator, params)
    |> HashPassword.changeset(params)
    |> apply_email_change
  end

  @doc """
  Changeset method allowing user to change their email, by first storing it as unconfirmed
  """
  def apply_email_change(changeset = %{params: %{"email" => email}, data: %{email: email_before}})
  when email != "" and email != nil and email != email_before do
    changeset
    |> Changeset.put_change(:unconfirmed_email, email)
    |> Confirmator.confirmation_needed_changeset
  end
  def apply_email_change(changeset), do: {nil, changeset}
end
