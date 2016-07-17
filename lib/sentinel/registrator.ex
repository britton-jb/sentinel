defmodule Sentinel.Registrator do
  alias Ecto.Changeset
  alias Sentinel.Util
  alias Sentinel.UserHelper

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
    updated_params = atomize_params(params) |> downcase_email

    UserHelper.model.changeset(struct(UserHelper.model), updated_params)
    |> Changeset.cast(updated_params, ~w(email), ~w())
    |> Changeset.validate_change(:email, &Util.presence_validator/2)
    |> Changeset.unique_constraint(:email)
    |> changeset_helper
  end

  defp username_changeset(params) do
    UserHelper.model.changeset(struct(UserHelper.model), params)
    |> Changeset.cast(params, ~w(username), ~w())
    |> Changeset.validate_change(:username, &Util.presence_validator/2)
    |> Changeset.unique_constraint(:username)
    |> Changeset.put_change(:hashed_confirmation_token, nil)
    |> Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
    |> changeset_helper
  end

  defp atomize_params(params) do
    for {key, val} <- params, into: %{} do
      cond do
        is_atom(key) -> {key, val}
        true -> {String.to_atom(key), val}
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
    |> set_hashed_password
  end

  def set_hashed_password(changeset = %{errors: [_]}), do: changeset
  def set_hashed_password(changeset = %{params: %{"password" => password}}) when password != "" and password != nil do
    hashed_password = Util.crypto_provider.hashpwsalt(password)


    case Enum.empty?(changeset.errors) do
      true -> changeset |> Changeset.put_change(:hashed_password, hashed_password)
      false -> changeset
    end
  end
  def set_hashed_password(changeset) do
    cond do
      !is_invitable? -> changeset |> Changeset.add_error(:password, "can't be blank")
      true -> changeset
    end
  end

  defp is_invitable? do
    Application.get_env(:sentinel, :invitable) || false
  end
end
