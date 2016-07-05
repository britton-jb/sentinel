defmodule Sentinel.Controllers.Json.User do
  use Phoenix.Controller
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  alias Sentinel.Mailer
  alias Sentinel.Util
  alias Sentinel.UserHelper
  alias Sentinel.PasswordResetter

  @doc """
  Sign up as a new user.
  Params should be:
  {user: {email: "user@example.com", password: "secret"}}
  If successfull, sends a welcome email.
  Responds with status 201 and body "ok" if successfull.
  Responds with status 422 and body {errors: {field: "message"}} otherwise.
  """
  def create(conn, params = %{"user" => %{"email" => email}}) when email != "" and email != nil do
    {confirmation_token, changeset} = Registrator.changeset(params["user"])
                                      |> Confirmator.confirmation_needed_changeset

    case Util.repo.insert(changeset) do
      {:ok, user} ->
        confirmable_and_invitable(conn, user, confirmation_token)
      {:error, changeset} ->
        Util.send_error(conn, changeset.errors)
    end
  end

  def create(conn, params = %{"user" => %{"username" => username}}) when username != "" and username != nil do
    {confirmation_token, changeset} = Registrator.changeset(params["user"])
                |> Confirmator.confirmation_needed_changeset

    case Util.repo.insert(changeset) do
      {:ok, user} ->
        confirmable_and_invitable(conn, user, confirmation_token)
      {:error, changeset} ->
        Util.send_error(conn, changeset.errors)
    end
  end

  def create(conn, params) do
    changeset = Registrator.changeset(params["user"])
    Util.send_error(conn, changeset.errors)
  end

  @doc """
  Confirm either a new user or an existing user's new email address.
  Parameter "id" should be the user's id.
  Parameter "confirmation" should be the user's confirmation token.
  If the confirmation matches, the user will be confirmed and signed in.
  Responds with status 201 and body {token: token} if successfull. Use this token in subsequent requests as authentication.
  Responds with status 422 and body {errors: {field: "message"}} otherwise.
  """
  def confirm(conn, params = %{"id" => user_id, "confirmation_token" => _}) do
    user = Util.repo.get!(UserHelper.model, user_id)
    changeset = Confirmator.confirmation_changeset(user, params)

    case Util.repo.update(changeset) do
      {:ok, user} -> encode_and_sign(conn, user)
      {:error, changeset} -> Util.send_error(conn, changeset.errors)
    end
  end

  def invited(conn, %{"id" => user_id} = params) do
    user = Util.repo.get!(UserHelper.model, user_id)
    changeset = PasswordResetter.reset_changeset(user, params)
      |> Confirmator.confirmation_changeset

    case Util.repo.update(changeset) do
      {:ok, updated_user} -> encode_and_sign(conn, updated_user)
      {:error, changeset} -> Util.send_error(conn, changeset.errors)
    end
  end

  defp confirmable_and_invitable(conn, user, confirmation_token) do
    case {is_confirmable, is_invitable} do
      {false, false} -> encode_and_sign(conn, user) # not confirmable or invitable - just log them in
      {_confirmable, :true} -> # must be invited
        {password_reset_token, changeset} = PasswordResetter.create_changeset(user)

        user = Util.repo.update!(changeset)
        Mailer.send_invite_email(user, {confirmation_token, password_reset_token}) |> Mailer.managed_deliver

        conn
        |> put_status(201)
        |> json(:ok)
      {:required, _invitable} -> # must be confirmed
        Mailer.send_welcome_email(user, confirmation_token) |> Mailer.managed_deliver

        conn
        |> put_status(201)
        |> json(:ok)
      {_confirmable_default, _invitable} -> # default behavior, optional confirmable, not invitable
        Mailer.send_welcome_email(user, confirmation_token) |> Mailer.managed_deliver
        encode_and_sign(conn, user)
    end
  end

  defp encode_and_sign(conn, user) do
    permissions = UserHelper.model.permissions(user.role)

    case Guardian.encode_and_sign(user, :token, permissions) do
      { :ok, token, _encoded_claims } -> conn
        |> put_status(201)
        |> json(%{token: token})
      { :error, :token_storage_failure } -> Util.send_error(conn, %{errors: "Failed to store session, please try to login again using your new password"})
      { :error, reason } -> Util.send_error(conn, %{errors: reason})
    end
  end

  defp is_confirmable do
    case Application.get_env(:sentinel, :confirmable) do
      :required -> :required
      :false -> :false
      _ -> :optional
    end
  end

  defp is_invitable do
    Application.get_env(:sentinel, :invitable) || :false
  end
end
