defmodule Sentinel.Controllers.Json.AccountController do
  @moduledoc """
  Handles the account show and update actions for JSON APIs
  """

  use Phoenix.Controller
  use Guardian.Phoenix.Controller

  alias Sentinel.Changeset.AccountUpdater
  alias Sentinel.Config
  alias Sentinel.Mailer
  alias Sentinel.Util

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated, handler: Config.auth_handler
  plug Guardian.Plug.LoadResource

  @doc """
  Get the account data for the current user
  Responds with status 200 and body view show JSON
  """
  def show(conn, _params, current_user, _claims \\ %{}) do
    json conn, Config.user_view.render("show.json", %{user: current_user})
  end

  @doc """
  Update email address or user params of the current user.
  If the email address should be updated, the user will receive an email to his new address.
  The stored email address will only be updated after clicking the link in that message.
  Responds with status 200 and the updated user if successfull.
  """
  def update(conn, %{"account" => params}, current_user, _claims) do
    {confirmation_token, changeset} = current_user |> AccountUpdater.changeset(params)

    case Config.repo.update(changeset) do
      {:ok, updated_user} ->
        send_new_email_address_confirmation_email(updated_user, confirmation_token)
        json conn, Config.user_view.render("show.json", %{user: updated_user})
      _ ->
        Util.send_error(conn, changeset.errors)
    end
  end

  defp send_new_email_address_confirmation_email(user, confirmation_token) do
    if confirmation_token != nil do
      user |> Mailer.send_new_email_address_email(confirmation_token)
    end
  end
end
