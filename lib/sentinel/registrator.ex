defmodule Sentinel.Registrator do
  alias Ecto.Changeset
  alias Sentinel.Util
  alias Sentinel.UserHelper

  @doc """
  Returns a changeset setting email and hashed_password on a new user.
  Validates that email and password are present and that email is unique.
  """
  def changeset(params = %{"username" => username}) when username != "" and username != nil do
    UserHelper.model.changeset(struct(UserHelper.model), params)
    |> Changeset.cast(params, ~w(username), ~w())
    |> Changeset.validate_change(:username, &Util.presence_validator/2)
    |> Changeset.unique_constraint(:username)
    |> Changeset.put_change(:hashed_confirmation_token, nil)
    |> Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
    |> changeset_helper
  end

  def changeset(params) do
    UserHelper.model.changeset(struct(UserHelper.model), params)
    |> Changeset.cast(params, ~w(email), ~w())
    |> Changeset.validate_change(:email, &Util.presence_validator/2)
    |> Changeset.unique_constraint(:email)
    |> changeset_helper
  end

  defp changeset_helper(changeset) do
    changeset
    |> UserHelper.validator
    |> set_hashed_password
  end

  def set_hashed_password(changeset = %{errors: [_]}), do: changeset
  def set_hashed_password(changeset = %{params: %{"password" => password}}) when password != "" and password != nil do
    hashed_password = Util.crypto_provider.hashpwsalt(password)

    changeset
    |> Changeset.put_change(:hashed_password, hashed_password)
  end
  def set_hashed_password(changeset) do
    if !is_invitable? do
      changeset = changeset
      |> Changeset.add_error(:password, "can't be blank")
    end

    changeset
  end

  defp is_invitable? do
    Application.get_env(:sentinel, :invitable) || false
  end
end
