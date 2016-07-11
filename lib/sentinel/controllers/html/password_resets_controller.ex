defmodule Sentinel.Controllers.Html.PasswordResets do
  use Phoenix.Controller
  use Guardian.Phoenix.Controller

  alias Sentinel.PasswordResetter
  alias Sentinel.Mailer
  alias Sentinel.Util
  alias Sentinel.UserHelper

  def new(conn, _params, _headers \\ %{}, _session \\ %{}) do
    conn
    |> put_status(:ok)
    |> render(Sentinel.PasswordResetView, "new.html")
  end

  @doc """
  Create a password reset token for a user
  Params should be:
  {email: "user@example.com"}
  If successfull, sends an email with instructions on how to reset the password.
  Responds with status 200 and body "ok" if successful or not, for security.
  """
  def create(conn, %{"email" => email}, _headers \\ %{}, _session \\ %{}) do
    user = UserHelper.find_by_email(email)
    {password_reset_token, changeset} = PasswordResetter.create_changeset(user)

    case Util.repo.update(changeset) do
      {:ok, updated_user} -> Mailer.send_password_reset_email(updated_user, password_reset_token)
      _ -> nil
    end

    conn
    |> put_status(:ok)
    |> put_flash(:info, "We'll send you an email to reset your password")
    |> render(Sentinel.PasswordResetView, "new.html")
  end

  @doc """
  Resets a users password if the provided token matches
  Params should be:
  {user_id: 1, password_reset_token: "abc123"}
  Responds with status 200 and body {token: token} if successfull. Use this token in subsequent requests as authentication.
  Responds with status 422 and body {errors: [messages]} otherwise.
  """
  def reset(conn, params = %{"user_id" => user_id}, _headers \\%{}, _session \\ %{}) do
    user = Util.repo.get(UserHelper.model, user_id)
    changeset = PasswordResetter.reset_changeset(user, params)

    case Util.repo.update(changeset) do
      {:ok, _updated_user} ->
        conn
        #|> Guardian.Plug.sign_in(updated_user) #FIXME do we actualy want it to sign you in herer?
        |> put_status(:ok)
        |> put_flash(:info, "Successfully reset your password")
        |> redirect(to: Sentinel.RouterHelper.helpers.sessions_path(conn, :new))
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Something went wrong. You may have taken too long to reset your password")
        |> render(Sentinel.PasswordResetView, "new.html")
    end
  end
end
