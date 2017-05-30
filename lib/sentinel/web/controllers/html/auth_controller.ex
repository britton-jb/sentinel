defmodule Sentinel.Controllers.Html.AuthController do
  @moduledoc """
  Handles the session create and destroy actions
  """
  require Ueberauth
  use Phoenix.Controller
  alias Sentinel.AfterRegistrator
  alias Sentinel.Config
  alias Sentinel.RedirectHelper
  alias Sentinel.RegistratorHelper
  alias Sentinel.Ueberauthenticator

  plug Ueberauth
  plug :put_layout, {Config.layout_view, Config.layout}
  plug Sentinel.Plug.AuthenticateResource, %{handler: Config.auth_handler} when action in [:delete]

  def request(conn, _params) do
    changeset = Sentinel.Session.changeset(%Sentinel.Session{})
    render(conn, Config.views.session, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    failed_to_authenticate(conn)
  end
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Ueberauthenticator.ueberauthenticate(auth) do
      {:ok, %{user: user, confirmation_token: confirmation_token}} ->
        new_user(conn, user, confirmation_token)
      {:ok, user} -> existing_user(conn, user)
      {:error, %{lockable: message}} ->
        changeset = Sentinel.Session.changeset(%Sentinel.Session{})
        conn
        |> put_status(401)
        |> put_flash(:error, message)
        |> render(Config.views.session, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
      {:error, _errors} ->
        failed_to_authenticate(conn)
    end
  end
  def callback(conn, _params), do: failed_to_authenticate(conn)

  defp failed_to_authenticate(conn) do
    changeset = Sentinel.Session.changeset(%Sentinel.Session{})
    conn
    |> put_status(401)
    |> put_flash(:error, "Failed to authenticate")
    |> render(Config.views.session, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
  end

  defp new_user(conn, user, confirmation_token) do
    with {:ok, user}                          <- AfterRegistrator.confirmable_and_invitable(user, confirmation_token),
         {:ok, user}                          <- RegistratorHelper.callback(user),
         ueberauth when not is_nil(ueberauth) <- Config.repo.get_by(Sentinel.Ueberauth, user_id: user.id),
         true                                 <- ueberauth.provider == "identity" && is_nil(ueberauth.hashed_password) do
      conn
      |> put_flash(:info, "Successfully invited user")
      |> RedirectHelper.redirect_from(:user_invited)
    else
      false ->
        confirmable_new_user(conn, user)
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: Config.router_helper.user_path(conn, :new))
      _ ->
        conn
        |> put_flash(:error, "There was an error creating your account")
        |> redirect(to: Config.router_helper.user_path(conn, :new))
    end
  end

  defp confirmable_new_user(conn, user) do
    case Config.confirmable do
      :required ->
        conn
        |> put_flash(:info, "You must confirm your account to continue. You will receive an email with instructions for how to confirm your email address in a few minutes.")
        |> RedirectHelper.redirect_from(:user_create_unconfirmed)
      :false ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Signed up")
        |> RedirectHelper.redirect_from(:user_create)
      _ ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "You will receive an email with instructions for how to confirm your email address in a few minutes.")
        |> RedirectHelper.redirect_from(:user_create)
    end
  end

  defp existing_user(conn, user) do
    conn
    |> Guardian.Plug.sign_in(user)
    |> put_flash(:info, "Logged in")
    |> RedirectHelper.redirect_from(:session_create)
  end

  @doc """
  Destroy the active session.
  Will delete the authentication token from the user table.
  """
  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out
    |> put_flash(:info, "Logged out successfully.")
    |> RedirectHelper.redirect_from(:session_delete)
  end

  @doc """
  Log in as an existing user.
  """
  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    auth = %Ueberauth.Auth{
      provider: :identity,
      credentials: %Ueberauth.Auth.Credentials{
        other: %{
          password: password
        }
      },
      uid: email
    }

    case Ueberauthenticator.ueberauthenticate(auth) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Logged in")
        |> RedirectHelper.redirect_from(:session_create)
      {:error, _errors} ->
        conn
        |> put_flash(:error, "Unknown username or password")
        |> RedirectHelper.redirect_from(:session_create_error)
    end
  end
end