Code.require_file "test/support/router.exs"

defmodule Sentinel.Endpoint do
  use Phoenix.Endpoint, otp_app: :sentinel

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_sentinel_test_key",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"

  plug Sentinel.TestRouter
end
