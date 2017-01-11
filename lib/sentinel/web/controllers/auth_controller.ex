defmodule Sentinel.Controllers.AuthController do
  @moduledoc """
  Handles the session create and destroy actions
  """

  require Ueberauth
  use Phoenix.Controller
  alias Plug.Conn
  alias Sentinel.AfterRegistrator
  alias Sentinel.Config
  alias Sentinel.Ueberauthenticator
  alias Sentinel.UserHelper
  alias Sentinel.Util
  alias Ueberauth.Strategy.Helpers

  plug Ueberauth
  plug Guardian.Plug.VerifyHeader when action in [:delete]
  plug Guardian.Plug.EnsureAuthenticated, %{handler: Config.auth_handler} when action in [:delete]
  plug Guardian.Plug.LoadResource when action in [:delete]

  def new(conn, _params) do
    changeset = Sentinel.Session.changeset(%Sentinel.Session{})
    render(conn, Sentinel.SessionView, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
  end

  #FIXME wtf does this do in the example app
  def request(conn, _params) do
    json conn, %{callback_url: Helpers.callback_url(conn)}
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    failed_to_authenticate(conn)
  end
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Ueberauthenticator.ueberauthenticate(auth) do
      {:ok, %{user: user, confirmation_token: confirmation_token}} ->
        new_user(conn, user, confirmation_token)
      {:ok, user} -> existing_user(conn, user)
      {:error, errors} ->
        failed_to_authenticate(conn)
    end
  end

  defp failed_to_authenticate(conn) do
    if conn.private.phoenix_format == "json" do
      Util.send_error(conn, %{error: "Failed to authenticate"}, 401)
    else
      changeset = Sentinel.Session.changeset(%Sentinel.Session{})
      conn
      |> put_status(401)
      |> put_flash(:error, "Failed to authenticate")
      |> render(Sentinel.SessionView, "new.html", %{conn: conn, changeset: changeset, providers: Config.ueberauth_providers})
    end
  end

  defp new_user(conn, user, confirmation_token) do
    {:ok, user} = AfterRegistrator.confirmable_and_invitable(user, confirmation_token)

    if conn.private.phoenix_format == "json" do
      conn
      |> put_status(201)
      |> json Config.user_view.render("show.json", %{user: user})
    else
      ueberauth = Config.repo.get_by(Sentinel.Ueberauth, provider: "identity", user_id: user.id)

      if is_nil(ueberauth.hashed_password) do
        conn
        |> put_flash(:info, "Successfully invited user")
        |> redirect(to: Config.router_helper.user_path(Config.endpoint, :new))
      else
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Signed up")
        |> redirect(to: Config.router_helper.account_path(Config.endpoint, :edit))
      end
    end
  end

  defp existing_user(conn, user) do
    if conn.private.phoenix_format == "json" do
      permissions = UserHelper.model.permissions(user.id)

      case Guardian.encode_and_sign(user, :token, permissions) do
        {:ok, token, _encoded_claims} ->
          conn
          |> put_status(201)
          |> json %{token: token}
          {:error, :token_storage_failure} -> Util.send_error(conn, %{error: "Failed to store session, please try to login again using your new password"})
          {:error, reason} -> Util.send_error(conn, %{error: reason})
      end
    else
      conn
      |> Guardian.Plug.sign_in(user)
      |> put_flash(:info, "Logged in")
      |> redirect(to: Config.router_helper.account_path(Config.endpoint, :edit))
    end
  end

  @doc """
  Destroy the active session.
  Will delete the authentication token from the user table.
  """
  def delete(conn, _params) do
    if conn.private.phoenix_format == "json" do
      token = conn |> Conn.get_req_header("authorization") |> List.first

      case Guardian.revoke! token do
        :ok -> json conn, :ok
        {:error, :could_not_revoke_token} -> Util.send_error(conn, %{error: "Could not revoke the session token"}, 422)
        {:error, error} -> Util.send_error(conn, error, 422)
      end
    else
      conn
      |> Guardian.Plug.sign_out
      |> put_flash(:info, "Logged out successfully.")
      |> redirect(to: "/")
    end
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
        if conn.private.phoenix_format == "json" do
          permissions = UserHelper.model.permissions(user.id)

          case Guardian.encode_and_sign(user, :token, permissions) do
            {:ok, token, _encoded_claims} -> json conn, %{token: token}
            {:error, :token_storage_failure} -> Util.send_error(conn, %{error: "Failed to store session, please try to login again using your new password"})
            {:error, reason} -> Util.send_error(conn, %{error: reason})
          end
        else
          conn
          |> Guardian.Plug.sign_in(user)
          |> put_flash(:info, "Logged in")
          |> redirect(to: Config.router_helper.account_path(Config.endpoint, :edit))
        end
      {:error, errors} ->
        if conn.private.phoenix_format == "json" do
          Util.send_error(conn, errors, 401)
        else
          conn
          |> put_flash(:error, "Unknown username or password")
          |> redirect(to: Config.router_helper.auth_path(Config.endpoint, :new))
        end
    end
  end
end
