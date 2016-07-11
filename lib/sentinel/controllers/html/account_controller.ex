defmodule Sentinel.Controllers.Html.Account do
  use Phoenix.Controller
  use Guardian.Phoenix.Controller

  alias Sentinel.Mailer
  alias Sentinel.Util
  alias Sentinel.AccountUpdater

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.EnsureAuthenticated, handler: Application.get_env(:sentinel, :auth_handler) || Sentinel.AuthHandler
  plug Guardian.Plug.LoadResource

  @doc """
  Get the account data for the current user
  Responds with status 200 and body view
  """
  def edit(conn, _params, current_user, _claims \\ %{}) do
    changeset = Sentinel.UserHelper.model.changeset(current_user)

    conn
    |> put_status(:ok)
    |> render(Sentinel.UserView, "edit.html", changeset: changeset, user: current_user)
  end

  @doc """
  Update email address and password of the current user.
  If the email address should be updated, the user will receive an email to his new address.
  The stored email address will only be updated after clicking the link in that message.
  Responds with status 200 and the updated user if successfull.
  """
  def update(conn, %{"account" => params}, current_user, _claims) do
    {confirmation_token, changeset} = current_user
                                      |> AccountUpdater.changeset(params)

    case Util.repo.update(changeset) do
      {:ok, updated_user} ->
        send_confirmation_email(updated_user, confirmation_token)
        success_changeset = Sentinel.UserHelper.model.changeset(updated_user)

        conn
        |> put_status(:ok)
        |> put_flash(:info, "Account updated")
        |> render(Sentinel.UserView, "edit.html", user: updated_user, changeset: success_changeset)
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:info, "Failed to update account")
        |> render(Sentinel.UserView, "edit.html", changeset: changeset, user: current_user)
    end
  end

  defp send_confirmation_email(user, confirmation_token) do
    if (confirmation_token != nil) do
      Mailer.send_new_email_address_email(user, confirmation_token)
      |> Mailer.managed_deliver
    end
  end
end
