defmodule Sentinel.Controllers.Unlock do
  use Phoenix.Controller
  alias Sentinel.{RedirectHelper, Config}

  def new(conn, _params) do
    render(conn, Config.views.unlock, "new.html", %{conn: conn})
  end

  def create(conn, %{"unlock" => {"email" => email}} = params) do
    with user <- Config.repo.get_by(Config.user_model, email: email),
         auth <- Config.repo.get_by(Sentinel.Ueberauth, provider: "identity", user_id: user.id) do
      Sentinel.Mailer.send_locked_account_email(user, auth.unlock_token)
    else
      _ -> nil
    end

    conn
    |> put_flash(:info, "We've sent an unlock email to that account")
    |> RedirectHelper.redirect_from(:unlock_create)
  end
  def create(conn, _params) do
    conn
    |> put_flash(:info, "We've sent an unlock email to that account")
    |> RedirectHelper.redirect_from(:unlock_create)
  end

  def unlock(conn, %{"unlock_token" => unlock_token} = params) do
    case Sentinel.Ueberauth.unlock(unlock_token) do
      {:ok, auth} ->
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