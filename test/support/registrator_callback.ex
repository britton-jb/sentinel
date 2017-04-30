defmodule Sentinel.TestRegistratorCallback do
  alias Sentinel.{User, TestRepo}

  def registrator_callback(user) do
    user
    |> User.changeset(%{role: "foo"})
    |> TestRepo.update!

    {:ok, user}
  end
end
