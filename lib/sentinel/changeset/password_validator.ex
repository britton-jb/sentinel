defmodule Sentinel.PasswordValidator do
  @moduledoc """
  Module responsible for implementing password validations,
  or pulling in the user's custom defined validations
  """

  def changeset(changeset, %{credentials: %{other: %{password: password}}}) when password != "" and password != nil do
    Sentinel.Helpers.InjectedChangesetHelper.apply(
      changeset,
      Sentinel.Config.password_validation,
      password
    )
  end
  def changeset(changeset, _params), do: changeset

  @doc """
  The default password validation provided by Sentinel.
  Ensures password is 8 characters or greater.
  """
  def default_sentinel_password_validation(changeset, password) do
    if String.length(password) >= 8 do
      changeset
    else
      Ecto.Changeset.add_error(
        changeset,
        :password,
        "Password must be at least 8 characters"
      )
    end
  end
end
