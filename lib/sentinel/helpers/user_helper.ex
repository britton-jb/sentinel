defmodule Sentinel.UserHelper do
  @moduledoc """
  User helper for Sentinel, pulling in the model, as well as a few query helper methods
  """

  alias Sentinel.Config
  alias Sentinel.UserHelper

  @doc """
  Wrapper for the user model passed in via sentinel configuration
  """
  def model do
    Config.user_model
  end

  @doc """
  Adds extra validator specified in configuration
  """
  def validator(changeset) do
    apply_validator(Config.user_model_validator, changeset)
  end
  defp apply_validator(nil, changeset), do: changeset
  defp apply_validator({mod, fun}, changeset), do: apply(mod, fun, [changeset])
  defp apply_validator(validator, changeset) do
    validator.(changeset)
  end
end
