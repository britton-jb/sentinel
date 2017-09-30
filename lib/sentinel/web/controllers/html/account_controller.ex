defmodule Sentinel.Controllers.Html.AccountController do
  @moduledoc """
  Handles the account show and update actions
  """

  use Phoenix.Controller

  alias Sentinel.{Config, Update}

  plug :put_layout, {Config.layout_view, Config.layout}
  plug Sentinel.AuthenticatedPipeline

  @doc """
  Get the account data for the current user
  """
  def edit(conn, _params) do
    current_user = Sentinel.Guardian.Plug.current_resource(conn)
    changeset = Config.user_model.changeset(current_user, %{})
    render(conn, Config.views.user, "edit.html", %{conn: conn, user: current_user, changeset: changeset})
  end

  @doc """
  Update email address or user params of the current user.
  If the email address should be updated, the user will receive an email to his new address.
  The stored email address will only be updated after clicking the link in that message.
  """
  def update(conn, %{"account" => params}) do
    current_user = Sentinel.Guardian.Plug.current_resource(conn)

    case Update.update(current_user, params) do
      {:ok, %{user: updated_user, auth: _auth, confirmation_token: confirmation_token}} ->
        Update.maybe_send_new_email_address_confirmation_email(updated_user, confirmation_token)
        new_changeset = Config.user_model.changeset(updated_user, %{})

        conn
        |> put_flash(:info, "Successfully updated user account")
        |> render(Config.views.user, "edit.html", %{conn: conn, user: updated_user, changeset: new_changeset})
      {:error, changeset} ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Failed to update user account")
        |> render(Config.views.user, "edit.html", %{conn: conn, user: current_user, changeset: changeset})
    end
  end
end
