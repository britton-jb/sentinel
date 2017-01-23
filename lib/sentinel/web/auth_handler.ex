defmodule Sentinel.AuthHandler do
  @moduledoc """
  Handles unauthorized & unauthenticated situations
  """

  use Phoenix.Controller

  alias Sentinel.Config
  alias Sentinel.Util

  @doc """
  Handles cases where the user fails to authenticate
  """
  def unauthenticated(conn = %{private: %{phoenix_format: "json"}}, _) do
    Util.send_error(conn, %{base: "Failed to authenticate"}, 401)
  end
  def unauthenticated(conn, _) do
    changeset = Sentinel.Session.changeset(%Sentinel.Session{})

    conn
    |> put_status(401)
    |> put_flash(:error, "Failed to authenticate")
    |> render(Sentinel.SessionView, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
  end

  @doc """
  Handles cases where the user fails authorization
  """
  def unauthorized(conn = %{private: %{phoenix_format: "json"}}, _) do
    Util.send_error(conn, %{base: "Unknown email or password"}, 403)
  end
  def unauthorized(conn, _) do
    render(conn, Config.error_view, "403.html", %{conn: conn})
  end
end
