defmodule Sentinel.Controllers.Html.User do
  use Phoenix.Controller

  def new(conn, _params) do
    changeset = Sentinel.UserHelper.model.changeset(struct(Sentinel.UserHelper.model))

    conn
    |> put_status(:ok)
    |> render(Sentinel.UserView, "new.html", changeset: changeset)
  end

  @doc """
  Sign up as a new user.
  If successfull, sends a welcome email.
  """
  def create(conn, params) do
    case Sentinel.UserRegistration.register(params) do
      {:ok, user} ->
        confirmable_and_invitable(conn, user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Unable to complete the registration")
        |> render(Sentinel.UserView, :new, changeset: changeset)
    end
  end

  defp confirmable_and_invitable(conn, user) do
    case {is_confirmable, is_invitable} do
      {false, false} -> # not confirmable or invitable
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_status(:created)
        |> put_flash(:info, "Successfully logged in")
        |> redirect(to: "/")
      {_confirmable, :true} -> # must be invited
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_status(:created)
        |> put_flash(:info, "Successfully invited the user")
        |> redirect(to: Sentinel.RouterHelper.helpers.user_path(conn, :new))
      {:required, _invitable} -> # must be confirmed
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_status(:created)
        |> put_flash(:info, "Successfully created account. Please confirm your account")
        |> redirect(to: Sentinel.RouterHelper.helpers.sessions_path(conn, :new))
      {_confirmable_default, _invitable} -> # default behavior, optional confirmable, not invitable
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_status(:created)
        |> put_flash(:info, "Successfully logged in. Please confirm your account")
        |> redirect(to: "/")
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

  def confirmation_instructions(conn, _params) do
    conn
    |> put_status(:ok)
    |> render(Sentinel.UserView, "confirmation_instructions.html")
  end

  def confirm(conn, params) do
    case Sentinel.UserRegistration.confirm(params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Successfully confirmed your account")
        |> put_status(:ok)
        |> redirect(to: Sentinel.RouterHelper.helpers.sessions_path(conn, :new))
      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Unable to confirm your account")
        |> redirect(to: Sentinel.RouterHelper.helpers.user_path(conn, :confirmation_instructions))
    end
  end

  def invited(conn, %{"id" => _user_id} = params) do
    case Sentinel.UserRegistration.invited(params) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_status(:created)
        |> put_flash(:info, "Successfully setup your account")
        |> redirect(to: Sentinel.RouterHelper.helpers.sessions_path(conn, :new))
      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Unable to setup your account")
        |> redirect(to: Sentinel.RouterHelper.helpers.user_path(:new))
    end
  end
end
