defmodule Sentinel.Controllers.Html.Sessions do
  use Phoenix.Controller
  alias Sentinel.Authenticator
  alias Sentinel.UserHelper
  alias Sentinel.Util

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.EnsureAuthenticated, %{ handler: Application.get_env(:sentinel, :auth_handler) || Sentinel.AuthHandler } when action in [:delete]
  plug Guardian.Plug.LoadResource

  def new(conn, _params) do
    changeset = Sentinel.Session.changeset(%Sentinel.Session{})

    conn
    |> put_status(:ok)
    |> render(Sentinel.SessionView, "new.html", changeset: changeset)
  end

  @doc """
  Log in as an existing user.
  Parameter are "username" and "password".
  """
  def create(conn, %{"username" => username, "password" => password}) do
    case Authenticator.authenticate_by_username(username, password) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Successfully logged in")
        |> redirect(to: "/")
      {:error, errors} ->
        changeset = Sentinel.Session.changeset(%Sentinel.Session{})

        conn
        |> put_flash(:error, "Unable to authenticate successfully")
        |> put_status(:unauthorized)
        |> redirect(to: Sentinel.RouterHelper.helpers.sessions_path(conn, :new))
    end
  end

  @doc """
  Log in as an existing user.
  Parameter are "email" and "password".
  """
  def create(conn, %{"email" => email, "password" => password}) do
    case Authenticator.authenticate_by_email(email, password) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Successfully logged in")
        |> redirect(to: "/")
      {:error, errors} ->
        changeset = Sentinel.Session.changeset(%Sentinel.Session{})

        conn
        |> put_flash(:error, "Unable to authenticate successfully")
        |> put_status(:unauthorized)
        |> redirect(to: Sentinel.RouterHelper.helpers.sessions_path(conn, :new))
    end
  end

  @doc """
  Destroy the active session.
  """
  def delete(conn, _params) do
    Guardian.Plug.sign_out(conn)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: Sentinel.RouterHelper.helpers.sessions_path(conn, :new))
  end
end
