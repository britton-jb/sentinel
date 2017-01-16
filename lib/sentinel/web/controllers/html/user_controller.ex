defmodule Sentinel.Controllers.Html.UserController do
  @moduledoc """
  Handles the user create, confirm and invite actions
  """
  use Phoenix.Controller
  alias Sentinel.Config

  @doc """
  Confirm either a new user or an existing user's new email address.
  Parameter "id" should be the user's id.
  Parameter "confirmation" should be the user's confirmation token.
  If the confirmation matches, the user will be confirmed and signed in.
  """
  def confirm(conn, params) do
    case Sentinel.Confirm.do_confirm(params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Successfully confirmed your account")
        |> redirect(to: "/")
      {:error, _changeset} ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Unable to confirm your account")
        |> redirect(to: "/")
    end
  end

  def invitation_registration(conn, params) do
    # FIXME actually write this
    render(conn, Sentinel.UserView, "edit.html", %{conn: conn, changeset: changeset})
  end

  def invited(conn, params) do
    case Sentinel.Invited.do_invited(params) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Signed up")
        |> redirect(to: Config.router_helper.account_path(Config.endpoint, :edit))
      {:error, changeset} ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Failed to create user")
        |> render(Sentinel.SessionView, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
    end
  end
end
