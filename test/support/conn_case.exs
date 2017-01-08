defmodule Sentinel.ConnCase do
  alias Sentinel.TestRepo

  use ExUnit.CaseTemplate
  using do
    quote do
      alias Plug.Conn
      alias Sentinel.Config
      alias Sentinel.Factory
      alias Sentinel.Mailer
      alias Sentinel.TestRepo
      alias Sentinel.TestRouter
      alias Sentinel.User

      import Mock
      import Sentinel.TestRouter.Helpers

      use Plug.Test
      use Phoenix.ConnTest
      use Bamboo.Test, shared: true

      @endpoint Sentinel.Endpoint
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
  end
end
