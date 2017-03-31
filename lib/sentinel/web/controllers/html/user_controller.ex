defmodule Sentinel.Controllers.Html.UserController do
  @moduledoc """
  Handles the user create, confirm and invite actions
  """
  use Phoenix.Controller
  alias Sentinel.Config

  plug :put_layout, {Config.layout_view, Config.layout}

  def new(conn, _params) do
    changeset = Config.user_model.changeset(struct(Config.user_model), %{})
    render(conn, Config.views.user, "new.html", %{conn: conn, changeset: changeset})
  end

  def confirmation_instructions(conn, _params) do
    render(conn, Sentinel.UserView, "confirmation_instructions.html", %{conn: conn})
  end
  def resend_confirmation_instructions(conn, params) do
    Sentinel.Confirm.send_confirmation_instructions(params)

    conn
    |> put_flash(:info, "Sent confirmation instructions")
    |> redirect(to: "/")
  end

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

  def invitation_registration(conn, %{"id" => id, "password_reset_token" => password_reset_token, "confirmation_token" => confirmation_token}) do
    changeset =
      Config.user_model
      |> Config.repo.get(id)
      |> Config.user_model.changeset(%{})

    render(conn, Config.views.user, "invitation_registration.html", %{
      conn: conn,
      changeset: changeset,
      user_id: id,
      password_reset_token: password_reset_token,
      confirmation_token: confirmation_token
    })
  end
  def invitation_registration(conn, _params) do
    conn
    |> put_status(422)
    |> put_flash(:error, "Invalid invitation tokens")
    |> redirect(to: "/")
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
        |> render(Config.views.session, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
    end
  end
end
