defmodule Sentinel.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias Sentinel.Util
  alias Sentinel.UserHelper

  def for_token(user) when user != "" and user != nil, do: { :ok, "User:#{user.id}" }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token("User:" <> id), do: { :ok, Util.repo.get(UserHelper.model, id) }
  def from_token(_), do: { :error, "Unknown resource type" }
end
