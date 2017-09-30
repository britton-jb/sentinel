defmodule Sentinel.Controllers.AuthController do
  @moduledoc """
  Handles the session create and destroy actions
  """

  require Ueberauth
  use Phoenix.Controller
  alias Sentinel.{Config, Controllers.Html, Controllers.Json}

  plug Ueberauth
  plug :put_layout, {Config.layout_view, Config.layout}
  plug Sentinel.AuthenticatedPipeline when action in [:delete]

  def new(conn, params) do
    if conn.private.phoenix_format == "json" do
      Json.AuthController.request(conn, params)
    else
      Html.AuthController.request(conn, params)
    end
  end

  def request(conn, params) do
    if conn.private.phoenix_format == "json" do
      Json.AuthController.request(conn, params)
    else
      Html.AuthController.request(conn, params)
    end
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
