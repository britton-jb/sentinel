defmodule Sentinel.Controllers.Json.PasswordController do
  @moduledoc """
  Handles the password create and reset actions for JSON APIs
  """
  use Phoenix.Controller
  use Guardian.Phoenix.Controller

  alias Sentinel.Changeset.PasswordResetter
  alias Sentinel.Config
  alias Sentinel.Mailer
  alias Sentinel.Util

  plug Sentinel.Plug.AuthenticateResource, %{handler: Config.auth_handler} when action in [:authenticated_update]

  @doc """
  Create a password reset token for a user
  Params should be:
  {email: "user@example.com"}
  If successfull, sends an email with instructions on how to reset the password.
  Responds with status 200 and body "ok" if successful or not, for security.
  """
  def new(conn, %{"email" => email}, _headers \\ %{}, _session \\ %{}) do
    user = Config.repo.get_by(Config.user_model, email: email)

    if is_nil(user) do
      json conn, :ok
    else
      auth = Config.repo.get_by(Sentinel.Ueberauth, user_id: user.id, provider: "identity")
      if is_nil(auth) do
        json conn, :ok
      else
        {password_reset_token, changeset} = auth |> PasswordResetter.create_changeset

        case Config.repo.update(changeset) do
          {:ok, updated_auth} ->
            updated_auth
            |> Config.repo.preload([:user])
            |> Map.get(:user)
            |> Mailer.send_password_reset_email(password_reset_token)
            _ -> nil
        end

        json conn, :ok
      end
    end
  end

  def edit(conn, params) do
    redirect(conn, external: Util.api_redirect_url(:password_reset, params))
  end

  @doc """
  Resets a users password if the provided token matches
  Params should be:
  {user_id: 1, password_reset_token: "abc123"}
  Responds with status 200 and body {token: token} if successfull. Use this token in subsequent requests as authentication.
  Responds with status 422 and body {errors: [messages]} otherwise.
  """
  def update(conn, params, headers \\ %{}, session \\ %{})
  def update(conn, params = %{"user_id" => user_id}, _headers, _session) do
    user = Config.repo.get(Config.user_model, user_id)

    case Sentinel.Update.update_password(user_id, params) do
      {:ok, _auth} ->
        permissions = Config.user_model.permissions(user.id)

        case Guardian.encode_and_sign(user, :token, permissions) do
          {:ok, token, _encoded_claims} -> json conn, %{token: token}
          {:error, :token_storage_failure} -> Util.send_error(conn, %{errors: "Failed to store session, please try to login again using your new password"})
          {:error, reason} -> Util.send_error(conn, %{errors: reason})
        end
      {:error, changeset} ->
        Util.send_error(conn, changeset.errors)
    end
  end

  def authenticated_update(conn, %{"account" => params}, user, _session) do
    auth = Config.repo.get_by(Sentinel.Ueberauth, user_id: user.id, provider: "identity")
    {password_reset_token, changeset} = auth |> PasswordResetter.create_changeset
    updated_auth = Config.repo.update!(changeset)

    password_reset_params = Util.params_to_ueberauth_auth_struct(params, password_reset_token)

    changeset =
      updated_auth
      |> PasswordResetter.reset_changeset(password_reset_params)

    case Config.repo.update(changeset) do
      {:ok, _updated_auth} ->
        json conn, Config.views.user.render("show.json", %{user: user})
      {:error, changeset} ->
        Util.send_error(conn, changeset.errors)
    end
  end
end
