defmodule Sentinel.Controllers.AuthController do
  @moduledoc """
  Handles the session create and destroy actions
  """

  require Ueberauth
  use Phoenix.Controller
  alias Sentinel.Controllers.Json
  alias Sentinel.Controllers.Html
  alias Sentinel.Config

  plug Ueberauth
  plug Guardian.Plug.VerifyHeader when action in [:delete]
  plug Guardian.Plug.EnsureAuthenticated, %{handler: Config.auth_handler} when action in [:delete]
  plug Guardian.Plug.LoadResource when action in [:delete]

  def new(conn, _params) do
    changeset = Sentinel.Session.changeset(%Sentinel.Session{})
    render(conn, Sentinel.SessionView, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
  end

  #FIXME wtf does this do in the example app
  def request(conn, _params) do
  end

  def callback(conn, params) do
    if conn.private.phoenix_format == "json" do
      Json.AuthController.callback(conn, params)
    else
      Html.AuthController.callback(conn, params)
    end
  end

  @doc """
  Destroy the active session.
  Will delete the authentication token from the user table.
  """
  def delete(conn, params) do
    if conn.private.phoenix_format == "json" do
      Json.AuthController.delete(conn, params)
    else
      Html.AuthController.delete(conn, params)
    end
  end

  @doc """
  Log in as an existing user.
  """
  def create(conn, params) do
    if conn.private.phoenix_format == "json" do
      Json.AuthController.create(conn, params)
    else
      Html.AuthController.create(conn, params)
    end
  end
end
