defmodule Sentinel.RegistratorCallback do
  @moduledoc """
  Handles user custom callbacks after registrator runs successfully
  """

  def run(user) do
    {:ok, user}
  end
end
