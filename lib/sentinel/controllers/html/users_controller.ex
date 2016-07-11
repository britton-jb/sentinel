defmodule Sentinel.Controllers.Html.User do
  use Phoenix.Controller
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  alias Sentinel.Mailer
  alias Sentinel.Util
  alias Sentinel.UserHelper
  alias Sentinel.PasswordResetter
  alias Sentinel.ViewHelper

  def new(conn, _params) do
    changeset = Sentinel.UserHelper.model.changeset(%{})

    conn
    |> put_status(:ok)
    |> render(Sentinel.UserView, "new.html", changeset: changeset)
  end

  @doc """
  Sign up as a new user.
  If successfull, sends a welcome email.
  """
  def create(conn, params = %{"user" => %{"email" => email}}) when email != "" and email != nil do
    {confirmation_token, changeset} = Registrator.changeset(params["user"])
                                      |> Confirmator.confirmation_needed_changeset

    case Util.repo.insert(changeset) do
      {:ok, user} ->
        confirmable_and_invitable(conn, user, confirmation_token)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Unable to complete the registration")
        |> render(Sentinel.UserView, :new, changeset: changeset)
    end
  end

  def create(conn, params = %{"user" => %{"username" => username}}) when username != "" and username != nil do
    {confirmation_token, changeset} = Registrator.changeset(params["user"])
                |> Confirmator.confirmation_needed_changeset

    case Util.repo.insert(changeset) do
      {:ok, user} ->
        confirmable_and_invitable(conn, user, confirmation_token)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Unable to complete the registration")
        |> render(Sentinel.UserView, :new, changeset: changeset)
    end
  end

  def create(conn, params) do
    changeset = Sentinel.UserHelper.model.changeset(%Sentinel.User{})

    conn
    |> put_status(:unprocessable_entity)
    |> put_flash(:error, "Unable to complete the registration")
    |> render(Sentinel.UserView, :new, changeset: changeset)
  end

  def confirmation_instructions(conn, _params) do
    conn
    |> put_status(:ok)
    |> render(Sentinel.UserView, "confirmation_instructions.html")
  end

  def confirm(conn, params = %{"email" => email, "confirmation_token" => _}) do
    user =
      case Util.repo.get_by(UserHelper.model, email: email) do
        nil -> Util.repo.get_by!(UserHelper.model, unconfirmed_email: email)
        user -> user
      end
    changeset = Confirmator.confirmation_changeset(user, params)

    case Util.repo.update(changeset) do
      {:ok, user} -> encode_and_sign(conn, user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Unable to confirm your account")
        |> redirect(to: Sentinel.RouterHelper.helpers.user_path(conn, :confirmation_instructions))
    end
  end
  def confirm(conn, params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_flash(:error, "Unable to confirm your account")
    |> redirect(to: Sentinel.RouterHelper.helpers.user_path(conn, :confirmation_instructions))
  end

  def invited(conn, %{"id" => user_id} = params) do
    user = Util.repo.get!(UserHelper.model, user_id)
    changeset = PasswordResetter.reset_changeset(user, params)
      |> Confirmator.confirmation_changeset

    case Util.repo.update(changeset) do
      {:ok, updated_user} -> encode_and_sign(conn, updated_user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Unable to confirm your account")
        |> redirect(to: Sentinel.RouterHelper.helpers.user_path(:new))
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
