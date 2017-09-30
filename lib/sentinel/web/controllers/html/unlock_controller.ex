defmodule Sentinel.Controllers.Html.UnlockController do
  use Phoenix.Controller
  alias Sentinel.RedirectHelper

  def new(conn, _params) do
    render(conn, Sentinel.Config.views.unlock, "new.html", %{conn: conn})
  end

  def create(conn, %{"unlock" => %{"email" => email}}) do
    Sentinel.Lockable.send_unlock_email(email)

    conn
    |> put_flash(:info, "We've sent an unlock email to that account")
    |> RedirectHelper.redirect_from(:unlock_create)
  end
  def create(conn, _params) do
    conn
    |> put_flash(:info, "We've sent an unlock email to that account")
    |> RedirectHelper.redirect_from(:unlock_create)
  end

  def update(conn, %{"unlock_token" => unlock_token}) do
    case Sentinel.Ueberauth.unlock(unlock_token) do
      {:ok, _auth} ->
        conn
        |> put_flash(:info, "Your account has been unlocked")
        |> RedirectHelper.redirect_from(:unlock_account)
      _ ->
        conn
        |> put_flash(:error, "Failed to unlock your account please try again")
        |> RedirectHelper.redirect_from(:unlock_account_error)
    end
  end
end
