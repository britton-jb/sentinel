defmodule Sentinel.AuthHandler do
  @moduledoc """
  Handles unauthorized & unauthenticated situations
  """

  alias Sentinel.Util

  @doc """
  Handles cases where the user fails to authenticate
  """
  def unauthenticated(conn, _) do
    Util.send_error(conn, %{base: "Failed to authenticate"}, 401)
  end

  @doc """
  Handles cases where the user fails authorization
  """
  def unauthorized(conn, _) do
    Util.send_error(conn, %{base: "Unknown email or password"}, 401)
  end
end
