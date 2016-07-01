defmodule Sentinel.Controllers.Users do
  use Phoenix.Controller
  alias Sentinel.UserRegistration
  alias Sentinel.Util

  @doc """
  Sign up as a new user.
  Params should be:
  {user: {email: "user@example.com", password: "secret"}}
  Or
  {user: {username: "my username", password: "secret"}}

  If successfull, sends a welcome email.
  Responds with status 201 and body "ok" if successfull.
  Responds with status 422 and body {errors: {field: "message"}} otherwise.
  """
  def create(conn, params) do
    case UserRegistration.register(conn, params) do
      {:ok, _reason} -> # User registered but not logged in (needs invite or activation)
        conn
        |> put_status(201)
        |> json(:ok)
      {:ok, user, token, claims} -> # User logged in
        conn
        |> put_status(201)
        |> json(%{token: token})
      {:error, reason} -> # Error
        Util.send_error(conn, reason)
    end
  end

  @doc """
  Confirm either a new user or an existing user's new email address.
  Parameter "id" should be the user's id.
  Parameter "confirmation" should be the user's confirmation token.
  If the confirmation matches, the user will be confirmed and signed in.
  Responds with status 201 and body {token: token} if successfull. Use this token in subsequent requests as authentication.
  Responds with status 422 and body {errors: {field: "message"}} otherwise.
  """
  def confirm(conn, params) do
    case UserRegistration.confirm(conn, params) do
      {:ok, user, token, claims} -> # User logged in
        conn
        |> put_status(201)
        |> json(%{token: token})
      {:error, reason} -> # Error
        Util.send_error(conn, reason)
    end
  end

  def invited(conn, params) do
    case UserRegistration.invited(conn, params) do
      {:ok, user, token, claims} -> # User logged in
        conn
        |> put_status(201)
        |> json(%{token: token})
      {:error, reason} -> # Error
        Util.send_error(conn, reason)
    end
  end
end
