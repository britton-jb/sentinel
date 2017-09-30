defmodule Sentinel.Controllers.Json.AccountController do
  @moduledoc """
  Handles the account show and update actions for JSON APIs
  """

  use Phoenix.Controller

  alias Sentinel.{Config, Util, Update}

  plug Sentinel.AuthenticatedPipeline

  @doc """
  Get the account data for the current user
  Responds with status 200 and body view show JSON
  """
  def show(conn, _params) do
    current_user = Sentinel.Guardian.Plug.current_resource(conn)
    json conn, Config.views.user.render("show.json", %{user: current_user})
  end

  @doc """
  Update email address or user params of the current user.
  If the email address should be updated, the user will receive an email to his new address.
  The stored email address will only be updated after clicking the link in that message.
  Responds with status 200 and the updated user if successfull.
  """
  def update(conn, %{"account" => params}) do
    current_user = Sentinel.Guardian.Plug.current_resource(conn)
    case Update.update(current_user, params) do
      {:ok, %{user: updated_user, auth: _auth, confirmation_token: confirmation_token}} ->
        Update.maybe_send_new_email_address_confirmation_email(updated_user, confirmation_token)
        json conn, Config.views.user.render("show.json", %{user: updated_user})
      {:error, changeset} ->
        Util.send_error(conn, changeset.errors)
    end
  end
end
