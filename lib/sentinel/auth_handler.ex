defmodule Sentinel.AuthHandler do
  def unauthorized(conn, _) do
    Sentinel.Util.send_error(conn, %{base: "Unknown email or password"}, 401)
  end

  def unauthenticated(conn, _) do
    Sentinel.Util.send_error(conn, %{base: "Forbidden"}, 403)
  end
end
