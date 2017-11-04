defmodule Sentinel.UserHelper do
  @moduledoc """
  User helper for Sentinel, pulling in the model, as well as a few query helper methods
  """
  alias Sentinel.Config

  @doc """
  Adds extra validator specified in configuration
  """
  def validator(changeset, params \\ %{}) do
    Sentinel.Helpers.InjectedChangesetHelper.apply(Config.user_model_validator, changeset, params)
  end
end
