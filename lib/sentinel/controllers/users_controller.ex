defmodule Sentinel.Controllers.Users do
  use Phoenix.Controller
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  alias Sentinel.Authenticator
  alias Sentinel.Mailer
  alias Sentinel.Util
  alias Sentinel.UserHelper

  @doc """
  Sign up as a new user.
  Params should be:
  {user: {email: "user@example.com", password: "secret"}}
  If successfull, sends a welcome email.
  Responds with status 200 and body "ok" if successfull.
  Responds with status 422 and body {errors: {field: "message"}} otherwise.
  """
  def create(conn, params = %{"user" => %{"email" => email}}) when email != "" and email != nil do
    {confirmation_token, changeset} = Registrator.changeset(params["user"])
                                      |> Confirmator.confirmation_needed_changeset

    if changeset.valid? do
      case Util.repo.transaction fn ->
        user = Util.repo.insert!(changeset)
      end do
        {:ok, user} ->
          confirmable(conn, user, confirmation_token)
      end
    else
      Util.send_error(conn, Enum.into(changeset.errors, %{}))
    end
  end

  def create(conn, params = %{"user" => %{"username" => username}}) when username != "" and username != nil do
    changeset = Registrator.changeset(params["user"])

    if changeset.valid? do
      case Util.repo.transaction fn ->
        Util.repo.insert(changeset)
      end do
        {:ok, user} ->
          confirmable(conn, user, "")
      end
    else
      Util.send_error(conn, Enum.into(changeset.errors, %{}))
    end
  end

  def create(conn, params) do
    changeset = Registrator.changeset(params["user"])
    Util.send_error(conn, Enum.into(changeset.errors, %{}))
  end

  @doc """
  Confirm either a new user or an existing user's new email address.
  Parameter "id" should be the user's id.
  Parameter "confirmation" should be the user's confirmation token.
  If the confirmation matches, the user will be confirmed and signed in.
  Responds with status 200 and body {token: token} if successfull. Use this token in subsequent requests as authentication.
  Responds with status 422 and body {errors: {field: "message"}} otherwise.
  """
  def confirm(conn, params = %{"id" => user_id, "confirmation_token" => _}) do
    user = Util.repo.get!(UserHelper.model, user_id)
    changeset = Confirmator.confirmation_changeset(user, params)

    if changeset.valid? do
      user = Util.repo.update!(changeset)
      permissions = UserHelper.model.permissions(user.role)

      case Guardian.encode_and_sign(user, :token, permissions) do
        { :ok, token, encoded_claims } -> json conn, %{token: token}
        { :error, :token_storage_failure } -> Util.send_error(conn, %{errors: "Failed to store session, please try to login again using your new password"})
        { :error, reason } -> Util.send_error(conn, %{errors: reason})
      end
    else
      Util.send_error(conn, Enum.into(changeset.errors, %{}))
    end
  end

  defp confirmable(conn, user, confirmation_token) do
    is_confirmable = Application.get_env(:sentinel, :confirmable)

    case is_confirmable do
      :required ->
        Mailer.send_welcome_email(user, confirmation_token)
        json conn, :ok
      :false ->
        permissions = UserHelper.model.permissions(user.role)

        case Guardian.encode_and_sign(user, :token, permissions) do
          { :ok, token, encoded_claims } -> json conn, %{token: token}
          { :error, :token_storage_failure } -> Util.send_error(conn, %{error: "Failed to store session, please try to login again using your new password"})
          { :error, reason } -> Util.send_error(conn, %{error: reason})
        end
      _ ->
        Mailer.send_welcome_email(user, confirmation_token)
        permissions = UserHelper.model.permissions(user.role)

        case Guardian.encode_and_sign(user, :token, permissions) do
          { :ok, token, encoded_claims } -> json conn, %{token: token}
          { :error, :token_storage_failure } -> Util.send_error(conn, %{error: "Failed to store session, please try to login again using your new password"})
          { :error, reason } -> Util.send_error(conn, %{error: reason})
        end
    end
  end
end
