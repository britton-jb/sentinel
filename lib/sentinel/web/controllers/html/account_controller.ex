defmodule Sentinel.Controllers.Html.AccountController do
  @moduledoc """
  Handles the account show and update actions
  """

  use Phoenix.Controller
  use Guardian.Phoenix.Controller

  alias Sentinel.Changeset.AccountUpdater
  alias Sentinel.Config
  alias Sentinel.Mailer

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated, handler: Config.auth_handler
  plug Guardian.Plug.LoadResource

  @doc """
  Get the account data for the current user
  """
  def edit(conn, _params, current_user, _claims \\ %{}) do
    changeset = Config.user_model.changeset(current_user, %{})
    render(conn, Config.user_view, "edit.html", %{conn: conn, user: current_user, changeset: changeset})
  end

  @doc """
  Update email address or user params of the current user.
  If the email address should be updated, the user will receive an email to his new address.
  The stored email address will only be updated after clicking the link in that message.
  """
  def update(conn, %{"account" => params}, current_user, _claims) do
    {confirmation_token, changeset} = current_user |> AccountUpdater.changeset(params)

    case Config.repo.update(changeset) do
      {:ok, updated_user} ->
        maybe_send_new_email_address_confirmation_email(updated_user, confirmation_token)
        new_changeset = Config.user_model.changeset(updated_user, %{})

        conn
        |> put_flash(:info, "Successfully updated user account")
        |> render(Config.user_view, "edit.html", %{conn: conn, user: updated_user, changeset: new_changeset})
      _ ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Failed to update user account")
        |> render(Config.user_view, "edit.html", %{conn: conn, user: current_user, changeset: changeset})
    end
  end

  defp maybe_send_new_email_address_confirmation_email(user, confirmation_token) do
    if confirmation_token != nil do
      user |> Mailer.send_new_email_address_email(confirmation_token)
    end
  end
end
