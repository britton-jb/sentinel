defmodule Sentinel.Controllers.Html.UserController do
  @moduledoc """
  Handles the user create, confirm and invite actions
  """
  use Phoenix.Controller
  alias Sentinel.{Config, RedirectHelper, Confirm}

  plug :put_layout, {Config.layout_view, Config.layout}

  def new(conn, _params) do
    changeset = Config.user_model.changeset(struct(Config.user_model), %{})
    render(conn, Config.views.user, "new.html", %{conn: conn, changeset: changeset})
  end

  def confirmation_instructions(conn, _params) do
    render(conn, Config.views.user, "confirmation_instructions.html", %{conn: conn})
  end
  def resend_confirmation_instructions(conn, params) do
    Confirm.send_confirmation_instructions(params)

    conn
    |> put_flash(:info, "Sent confirmation instructions")
    |> RedirectHelper.redirect_from(:user_confirmation_sent)
  end

  @doc """
  Confirm either a new user or an existing user's new email address.
  Parameter "id" should be the user's id.
  Parameter "confirmation" should be the user's confirmation token.
  If the confirmation matches, the user will be confirmed and signed in.
  """
  def confirm(conn, params) do
    case Confirm.do_confirm(params) do
      {:ok, user} ->
        conn
        |> Sentinel.Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Successfully confirmed your account")
        |> RedirectHelper.redirect_from(:user_confirmation)
      {:error, :bad_request} ->
        conn
        |> RedirectHelper.redirect_from(:user_confirmation_error)
      {:error, _changeset} ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Unable to confirm your account")
        |> RedirectHelper.redirect_from(:user_confirmation_error)
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
      confirmation_token: confirmation_token,
      providers: Config.ueberauth_providers
    })
  end
  def invitation_registration(conn, _params) do
    conn
    |> put_status(422)
    |> put_flash(:error, "Invalid invitation tokens")
    |> RedirectHelper.redirect_from(:user_invitation_error)
  end

  def invited(conn, params) do
    case Sentinel.Invited.do_invited(params) do
      {:ok, user} ->
        conn
        |> Sentinel.Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Signed up")
        |> RedirectHelper.redirect_from(:user_invitation)
      {:error, changeset} ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Failed to create user")
        |> render(Config.views.session, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
    end
  end
end
