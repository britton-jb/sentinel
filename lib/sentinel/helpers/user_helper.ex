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
    Sentinel.Helpers.InjectedChangesetHelper.apply(Config.user_model_validator, changeset, params)
  end
end
