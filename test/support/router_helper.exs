defmodule Sentinel.TestRouter do
  use Phoenix.Router
  require Sentinel

  pipeline :api do
    plug :accepts, ~w(json)
  end

  pipeline :browser do
    plug Plug.RequestId

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison

    plug Plug.Session,
      store: :cookie,
      key: "_sentinel_key",
      encryption_salt: "encrypted cookie salt",
      signing_salt: "signing salt"

    plug :secret_key_setup
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser
    Sentinel.mount_html
  end

  scope "/api" do
    pipe_through :api
    Sentinel.mount_api
  end

  defp secret_key_setup(conn, _opts) do
    conn.secret_key_base
    |> put_in(String.duplicate("secret", 12))
  end
end

defmodule RouterHelper do
  use Plug.Test

  @default_opts [
    store: :cookie,
    key: "_sentinel_test_key",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]
  @secret String.duplicate("secret", 12)

  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))
  def call(router, verb, path, params \\ nil, headers \\ []) do
    conn = Plug.Test.conn(verb, path, params)
    conn = Enum.reduce(headers, conn, fn ({name, value}, conn) ->
        put_req_header(conn, name, value)
      end) |> Plug.Conn.fetch_query_params(conn)

    keyed_conn =
      conn.secret_key_base
      |> put_in(@secret)
      |> Plug.Session.call(@signing_opts)
      |> Plug.Conn.fetch_session

    router.call(keyed_conn, router.init([]))
  end
end

defmodule HtmlRequestHelper do
  use Phoenix.ConnTest

  @default_opts [
    store: :cookie,
    key: "_sentinel_test_key",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]
  @secret String.duplicate("secret", 12)

  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

  def call_with_session(user, router, verb, path, params \\ nil) do
    conn =
      Plug.Test.conn(verb, path, params)
      |> Plug.Conn.fetch_query_params

    session_conn =
      conn.secret_key_base
      |> put_in(@secret)
      |> Plug.Session.call(@signing_opts)
      |> Plug.Conn.fetch_session
      |> Guardian.Plug.sign_in(user)

    router.call(session_conn, router.init([]))
  end
end
