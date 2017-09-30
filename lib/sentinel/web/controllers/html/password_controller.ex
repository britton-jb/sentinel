defmodule Sentinel.Controllers.Html.PasswordController do
  @moduledoc """
  Handles the password create and reset actions
  """
  use Phoenix.Controller

  alias Sentinel.{Changeset.PasswordResetter, Config, Mailer, RedirectHelper, Util}

  plug :put_layout, {Config.layout_view, Config.layout}
  plug Sentinel.AuthenticatedPipeline when action in [:authenticated_update]

  def new(conn, _params) do
    render(conn, Config.views.password, "new.html", %{conn: conn})
  end

  def create(conn, %{"password" => %{"email" => email}}) do
    user = Config.repo.get_by(Config.user_model, email: email)

    if is_nil(user) do
      send_redirect_and_flash(conn)
    else
      auth = Config.repo.get_by(Sentinel.Ueberauth, user_id: user.id, provider: "identity")
      if is_nil(auth) do
        send_redirect_and_flash(conn)
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

        send_redirect_and_flash(conn)
      end
    end
  end

  defp send_redirect_and_flash(conn) do
    conn
    |> put_flash(:info, "You'll receive an email with instructions about how to reset your password in a few minutes.")
    |> RedirectHelper.redirect_from(:password_create)
  end

  def edit(conn, params)
  def edit(conn, %{"user_id" => user_id, "password_reset_token" => password_reset_token}) do
    render(conn, Config.views.password, "edit.html", %{conn: conn, password_reset_token: password_reset_token, user_id: user_id})
  end
  def edit(conn, _params) do
    conn
    |> put_flash(:error, "Invalid password reset link. Please try again.")
    |> RedirectHelper.redirect_from(:password_update_error)
  end

  @doc """
  Resets a users password if the provided token matches
  Params should be:
  {user_id: 1, password_reset_token: "abc123"}
  """
  def update(conn, params)
  def update(conn, %{"password" => %{"user_id" => user_id, "password_reset_token" => _password_reset_params} = params}) do
    user = Config.repo.get(Config.user_model, user_id)

    case Sentinel.Update.update_password(user_id, params) do
      {:ok, _auth} ->
        conn
        |> Sentinel.Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Successfully updated password")
        |> RedirectHelper.redirect_from(:password_update)
      {:error, _changeset} ->
        conn
        |> put_status(422)
        |> put_flash(:error, "Unable to reset your password")
        |> RedirectHelper.redirect_from(:password_update_unsuccessful)
    end
  end
  def update(conn, _params) do
    conn
    |> put_status(422)
    |> put_flash(:error, "Unable to reset your password")
    |> RedirectHelper.redirect_from(:password_update_unsuccessful)
  end

  def authenticated_update(conn, %{"account" => params}) do
    current_user = Sentinel.Guardian.Plug.current_resource(conn)
    auth = Config.repo.get_by(Sentinel.Ueberauth, user_id: current_user.id, provider: "identity")
    {password_reset_token, changeset} = auth |> PasswordResetter.create_changeset
    updated_auth = Config.repo.update!(changeset)

    password_reset_params = Util.params_to_ueberauth_auth_struct(params, password_reset_token)

    changeset =
      updated_auth
      |> PasswordResetter.reset_changeset(password_reset_params)

    case Config.repo.update(changeset) do
      {:ok, _updated_auth} ->
        conn
        |> put_flash(:info, "Update successful")
        |> RedirectHelper.redirect_from(:password_update)
      {:error, changeset} ->
        render(conn, Config.views.password, "edit.html", %{conn: conn, user: current_user, changeset: changeset})
    end
  end
end
