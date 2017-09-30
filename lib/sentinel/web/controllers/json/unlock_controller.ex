defmodule Sentinel.Controllers.Json.UnlockController do
  use Phoenix.Controller
  alias Sentinel.RedirectHelper

  def create(conn, %{"email" => email}) do
    Sentinel.Lockable.send_unlock_email(email)
    json conn, :ok
  end

  def update(conn, %{"unlock_token" => unlock_token}) do
    case Sentinel.Ueberauth.unlock(unlock_token) do
      {:ok, _auth} -> RedirectHelper.api_redirect(conn, :unlock_account)
      _ -> RedirectHelper.api_redirect(conn, :unlock_account_error)
    end
  end
end
