defmodule Sentinel.Controllers.Json.UserController do
  @moduledoc """
  Handles the user create, confirm and invite actions for JSON APIs
  """

  use Phoenix.Controller
  alias Sentinel.{Config, Util}

  def resend_confirmation_instructions(conn, params) do
    Sentinel.Confirm.send_confirmation_instructions(params)
    json conn, :ok
  end

  @doc """
  Confirm either a new user or an existing user's new email address.
  Parameter "id" should be the user's id.
  Parameter "confirmation" should be the user's confirmation token.
  If the confirmation matches, the user will be confirmed and signed in.
  Responds with status 201 and body {token: token} if successfull.
  Use this token in subsequent requests as authentication.
  Responds with status 422 and body {errors: {field: "message"}} otherwise.
  """
  def confirm(conn, params) do
    case Sentinel.Confirm.do_confirm(params) do
      {:ok, _user} -> Sentinel.RedirectHelper.api_redirect(conn, :user_confirmation)
      {:error, changeset} -> Util.send_error(conn, changeset.errors)
    end
  end

  def invitation_registration(conn, params) do
    Sentinel.RedirectHelper.api_redirect(conn, :user_invitation, params)
  end

  @doc """
  Creates a new user using the invitable flow, without a password. This sends
  them an email which links to an endpoint where they can create a password
  and fill in other account information
  """
  def invited(conn, params) do
    case Sentinel.Invited.do_invited(params) do
      {:ok, user} ->
        conn
        |> put_status(200)
        |> render(Config.views.user, "show.json", %{user: user})
      {:error, changeset} -> Util.send_error(conn, changeset.errors)
    end
  end
end
