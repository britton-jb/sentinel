defmodule Sentinel.AuthHandler do
  @moduledoc """
  Handles unauthorized & unauthenticated situations
  """
  import Plug.Conn
  use Phoenix.Controller

  alias Sentinel.{Config, Util, Session}

  def auth_error(%{private: %{phoenix_format: "json"}} = conn, {:unauthenticated, :unauthenticated}, _opts) do
    Util.send_error(conn, %{base: "Failed to authenticate"}, 401)
  end
  def auth_error(%{private: %{phoenix_format: "json"}} = conn, {:unauthorized, :unauthorized}, _opts) do
    Util.send_error(conn, %{base: "Unknown email or password"}, 403)
  end
  def auth_error(%{private: %{phoenix_format: "json"}} = conn, {:no_resource_found, :no_resource_found}, _opts) do
    Util.send_error(conn, %{base: "Resource not found"}, 404)
  end
  def auth_error(conn, {:unauthenticated, :unauthenticated}, _opts) do
    changeset = Session.changeset(%Session{})

    conn
    |> put_status(401)
    |> put_flash(:error, "Failed to authenticate")
    |> render(Config.views.session, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
  end
  def auth_error(conn, {:unauthorized, :unauthorized}, _opts) do
    render(conn, Config.views.error, "403.html", %{conn: conn})
  end
  def auth_error(conn, {:no_resource_found, :no_resource_found}, _opts) do
    render(conn, Config.views.error, "404.html", %{conn: conn})
  end
end
