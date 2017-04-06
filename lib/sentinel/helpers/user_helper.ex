defmodule Sentinel.UserHelper do
  @moduledoc """
  User helper for Sentinel, pulling in the model, as well as a few query helper methods
  """
  alias Sentinel.Config

  @doc """
  Wrapper for the user model passed in via sentinel configuration
  """
  def model do
    Config.user_model
  end

  @doc """
  Adds extra validator specified in configuration
  """
  def validator(changeset, params \\ %{}) do
    apply_validator(Config.user_model_validator, changeset, params)
  end
  defp apply_validator(nil, changeset, _params), do: changeset
  defp apply_validator({mod, fun}, changeset, params), do: apply(mod, fun, [changeset, params])
  defp apply_validator(validator, changeset, params) do
    validator.(changeset, params)
  end
end
