defmodule Sentinel.RegistratorHelper do
  @moduledoc """
  Registrator helper for Sentinel
  """
  alias Sentinel.Config

  @doc """
  Adds extra registrator callback specified in configuration
  """
  def callback(user) do
    apply_callback(Config.registrator_callback, user)
  end
  defp apply_callback(nil, user), do: {:ok, user}
  defp apply_callback({module, function}, user), do: Kernel.apply(module, function, [user])
end
