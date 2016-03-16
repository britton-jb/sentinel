defmodule Sentinel.Controllers.Account do
  use Phoenix.Controller
  use Guardian.Phoenix.Controller

  alias Sentinel.ViewHelper
  alias Sentinel.Mailer
  alias Sentinel.Util
  alias Sentinel.AccountUpdater

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource
  plug Guardian.Plug.EnsureAuthenticated, handler: Application.get_env(:sentinel, :auth_handler) || Sentinel.Authandler

  @doc """
  Get the account data for the current user
  Responds with status 200 and body view show JSON
  """
  def show(conn, _params, current_user, _claims \\ %{}) do
    json conn, ViewHelper.user_view.render("show.json", %{user: current_user})
  end

  @doc """
  Update email address and password of the current user.
  If the email address should be updated, the user will receive an email to his new address.
  The stored email address will only be updated after clicking the link in that message.
  Responds with status 200 and body "ok" if successfull.
  """
  def update(conn, %{"account" => params}, current_user, _claims) do
    {confirmation_token, changeset} = current_user
                                      |> AccountUpdater.changeset(params)
    if changeset.valid? do
      case Util.repo.transaction fn ->
        current_user = Util.repo.update!(changeset)
        if (confirmation_token != nil) do
          Mailer.send_new_email_address_email(current_user, confirmation_token)
        end
      end do
        {:ok, _} -> json conn, :ok
      end
    else
      Util.send_error(conn, Enum.into(changeset.errors, %{}))
    end
  end
end
