defmodule Sentinel.Changeset.Registrator do
  alias Ecto.Changeset
  alias Ecto.DateTime
  alias Sentinel.Util
  alias Sentinel.UserHelper

  @moduledoc """
  Handles registration changeset logic
  """

  @doc """
  Returns a changeset setting email and hashed_password on a new user.
  Validates that email and password are present and that email is unique.
  """
  def changeset(params = %{"username" => username}) when username != "" and username != nil do
    username_changeset(params)
  end
  def changeset(params = %{username: username}) when username != "" and username != nil do
    username_changeset(params)
  end
  def changeset(params) do
    updated_params = params |> atomize_params |> downcase_email

    Sentinel.Config.user_model
    |> struct
    |> UserHelper.model.changeset(updated_params)
    |> Changeset.cast(updated_params, ~w(email), ~w())
    |> Changeset.validate_change(:email, &Util.presence_validator/2)
    |> Changeset.unique_constraint(:email)
    |> changeset_helper
  end

  defp username_changeset(params) do
    UserHelper.model
    |> struct
    |> UserHelper.model.changeset(params)
    |> Changeset.cast(params, ~w(username), ~w())
    |> Changeset.validate_change(:username, &Util.presence_validator/2)
    |> Changeset.unique_constraint(:username)
    |> Changeset.put_change(:hashed_confirmation_token, nil)
    |> Changeset.put_change(:confirmed_at, DateTime.utc)
    |> changeset_helper
  end

  defp atomize_params(params) do
    for {key, val} <- params, into: %{} do
      if is_atom(key) do
        {key, val}
      else
        {String.to_atom(key), val}
      end
    end
  end

  defp downcase_email(atomized_params) do
    case Map.get(atomized_params, :email) do
      nil -> atomized_params
      _ -> Map.update!(atomized_params, :email, &(String.downcase(&1)))
    end
  end

  defp changeset_helper(changeset) do
    changeset
    |> UserHelper.validator
  end
end
