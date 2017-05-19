defmodule Sentinel.Controllers.Json.AuthController do
  @moduledoc """
  Handles the session create and destroy actions for JSON APIs
  """

  require Ueberauth
  use Phoenix.Controller
  alias Plug.Conn
  alias Sentinel.AfterRegistrator
  alias Sentinel.Config
  alias Sentinel.RegistratorHelper
  alias Sentinel.Ueberauthenticator
  alias Sentinel.UserHelper
  alias Sentinel.Util

  plug Ueberauth
  plug Sentinel.Plug.AuthenticateResource, %{handler: Config.auth_handler} when action in [:delete]

  def request(conn, _params) do
    json conn, %{providers: Config.ueberauth_providers}
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    Util.send_error(conn, %{error: "Failed to authenticate"}, 401)
  end
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Ueberauthenticator.ueberauthenticate(auth) do
      {:ok, %{user: user, confirmation_token: confirmation_token}} ->
        new_user(conn, user, confirmation_token)
      {:ok, user} -> existing_user(conn, user)
      {:error, errors} -> Util.send_error(conn, errors, 401)
    end
  end

  defp new_user(conn, user, confirmation_token) do
    with {:ok, user} <- AfterRegistrator.confirmable_and_invitable(user, confirmation_token),
         {:ok, user} <- RegistratorHelper.callback(user) do
      conn
      |> put_status(201)
      |> json(Config.views.user.render("show.json", %{user: user}))
    end
  end

  defp existing_user(conn, user) do
    permissions = UserHelper.model.permissions(user.id)

    case Guardian.encode_and_sign(user, :token, permissions) do
      {:ok, token, _encoded_claims} ->
        conn
        |> put_status(201)
        |> json(%{token: token})
        {:error, :token_storage_failure} -> Util.send_error(conn, %{error: "Failed to store session, please try to login again using your new password"})
        {:error, reason} -> Util.send_error(conn, %{error: reason})
    end
  end

  @doc """
  Destroy the active session.
  Will delete the authentication token from the user table.
  Responds with status 200 if no error occured.
  """
  def delete(conn, _params) do
    token = conn |> Conn.get_req_header("authorization") |> List.first

    case Guardian.revoke! token do
      :ok -> json conn, :ok
      {:error, :could_not_revoke_token} -> Util.send_error(conn, %{error: "Could not revoke the session token"}, 422)
      {:error, error} -> Util.send_error(conn, error, 422)
    end
  end

  @doc """
  Log in as an existing user.
  Parameter are "email" and "password".
  Responds with status 200 and {token: token} if credentials were correct.
  Responds with status 401 and {errors: error_message} otherwise.
  """
  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
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
        permissions = UserHelper.model.permissions(user.id)

        case Guardian.encode_and_sign(user, :token, permissions) do
          {:ok, token, _encoded_claims} -> json conn, %{token: token}
          {:error, :token_storage_failure} -> Util.send_error(conn, %{error: "Failed to store session, please try to login again using your new password"})
          {:error, reason} -> Util.send_error(conn, %{error: reason})
        end
      {:error, errors} -> Util.send_error(conn, errors, 401)
    end
  end
end
