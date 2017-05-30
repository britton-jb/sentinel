defmodule Sentinel.Controllers.UnlockController do
  use Phoenix.Controller
  alias Sentinel.{RedirectHelper, Config}

  def create(conn, %{"email" => email } = params) do
    with user <- Config.repo.get_by(Config.user_model, email: email),
         auth <- Config.repo.get_by(Sentinel.Ueberauth, provider: "identity", user_id: user.id) do
      Sentinel.Mailer.send_locked_account_email(user, auth.unlock_token)
    else
      _ -> nil
    end

    json conn, :ok
  end

  def unlock(conn, %{"unlock_token" => unlock_token} = params) do
    case Sentinel.Ueberauth.unlock(unlock_token) do
      {:ok, auth} ->
        RedirectHelper.api_redirect(conn, :unlock_account)
      _ ->
        RedirectHelper.api_redirect(conn, :unlock_account_error)
    end
  end
end