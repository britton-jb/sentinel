defmodule Sentinel.Changeset.HashPassword do
  @moduledoc """
  Module responsible the password hashing utilized in Sentinel, to be easily
  pulled out and used oustide Sentinel if necessary, or redefined
  """

  alias Ecto.Changeset
  alias Sentinel.Config

  @doc """
  Handles ueberauth model changeset validations for passwords, and hashes them if
  necessary
  """
  def changeset(changeset, %{credentials: %{other: %{password: password, password_confirmation: password}}}) when password != "" and password != nil do
    hashed_password = Config.crypto_provider.hashpwsalt(password)

    case Enum.empty?(changeset.errors) do
      true -> changeset |> Changeset.put_change(:hashed_password, hashed_password)
      false -> changeset
    end
  end
  def changeset(changeset, %{credentials: %{other: %{password: password, password_confirmation: _no_match}}}) when password != "" and password != nil do
    if not invitable?() && being_created?(changeset) do
      changeset |> Changeset.add_error(:password, "password and confirmation must match")
    else
      changeset
    end
  end
  def changeset(changeset, %{credentials: %{other: %{password: _}}}) do
    if invitable?() && being_created?(changeset) do
      changeset
    else
      changeset |> Changeset.add_error(:password, "can't be blank")
    end
  end
  def changeset(changeset, _params) do
    if not invitable?() && being_created?(changeset) do
      changeset |> Changeset.add_error(:password, "can't be blank")
    else
      changeset
    end
  end

  defp invitable? do
    Config.invitable
  end
  defp being_created?(changeset) do # NOTE might need to make this more robust
    changeset.data |> Map.get(:id) |> is_nil
  end
end
