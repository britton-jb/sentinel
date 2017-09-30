defmodule Sentinel.ConnCase do
  alias Sentinel.TestRepo

  use ExUnit.CaseTemplate, async: true
  @default_opts [
    store: :cookie,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]
  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

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

  def conn_with_fetched_session(the_conn) do
    the_conn.secret_key_base
    |> put_in(@secret)
    |> Plug.Session.call(@signing_opts)
    |> Plug.Conn.fetch_session
  end

  def run_plug(conn, plug_module) do
    opts = apply(plug_module, :init, [])
    apply(plug_module, :call, [conn, opts])
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
  end
end
