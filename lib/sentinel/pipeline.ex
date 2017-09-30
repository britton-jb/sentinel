defmodule Sentinel.Pipeline do
  @moduledoc """
  Implements guardian pipeline for use in Sentinel generated routes,
  and the greater Phoenix application
  """

  use Guardian.Plug.Pipeline, otp_app: Sentinel.Config.otp_app(),
    module: Sentinel.Guardian,
    error_handler: Sentinel.AuthHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.VerifyCookie
  plug Guardian.Plug.LoadResource, allow_blank: true
end
