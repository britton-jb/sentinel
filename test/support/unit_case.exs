defmodule Sentinel.UnitCase do
  alias Sentinel.TestRepo

  use ExUnit.CaseTemplate, async: true
  using do
    quote do
      alias Sentinel.Config
      alias Sentinel.Factory
      alias Sentinel.TestRepo
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
  end
end
