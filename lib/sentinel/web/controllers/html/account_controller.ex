defmodule Sentinel.Controllers.Html.AccountController do
  @moduledoc """
  Handles the account show and update actions
  """

  use Phoenix.Controller
  use Guardian.Phoenix.Controller

  alias Sentinel.Config
  alias Sentinel.Update

  plug :put_layout, {Config.layout_view, Config.layout}
  plug Guardian.Plug.VerifySession
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
    case Update.update(current_user, params) do
      {:ok, %{user: updated_user, auth: _auth, confirmation_token: confirmation_token}} ->
        Update.maybe_send_new_email_address_confirmation_email(updated_user, confirmation_token)
        new_changeset = Config.user_model.changeset(updated_user, %{})

        conn
        |> put_flash(:info, "Successfully updated user account")
        |> render(Config.user_view, "edit.html", %{conn: conn, user: updated_user, changeset: new_changeset})
      {:error, changeset} ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Failed to update user account")
        |> render(Config.user_view, "edit.html", %{conn: conn, user: current_user, changeset: changeset})
    end
  end
end
