defmodule Sentinel.GuardianSerializer do
  @moduledoc """
  Serializer for Guardian. More information available at https://github.com/ueberauth/guardian
  """

  @behaviour Guardian.Serializer

  alias Sentinel.Config
  alias Sentinel.UserHelper

  @doc """
  Serializes user for a token
  """
  def for_token(user) when user != "" and user != nil, do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  @doc """
  Serializes use from a token
  """
  def from_token("User:" <> id), do: {:ok, Config.repo.get(UserHelper.model, id)}
  def from_token(_), do: {:error, "Unknown resource type"}
end
