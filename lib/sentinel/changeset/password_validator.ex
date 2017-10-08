defmodule Sentinel.PasswordValidator do
  @moduledoc """
  Module responsible for implementing password validations,
  or pulling in the user's custom defined validations
  """

  def changeset(changeset, %{credentials: %{other: %{password: password}}}) when password != "" and password != nil do
    apply_password_validation(
      Sentinel.Config.password_validation,
      changeset,
      password
    )
  end
  def changeset(changeset, _params), do: changeset

  defp apply_password_validation(nil, changeset, password) do
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
  defp apply_password_validation({module, function}, changeset, password) do
    Kernel.apply(module, function, [changeset, password])
  end
end
