defmodule Html.ResetPasswordControllerTest do
  use Sentinel.TestCase
  use Plug.Test
  import RouterHelper
  alias Sentinel.TestRouter
  alias Sentinel.Registrator
  alias Sentinel.PasswordResetter
  import Sentinel.Util

  @email "user@example.com"

  test "visit the forgot your password page" do
    conn = call(TestRouter, :get, "/password_resets")

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Forgot your password?")
  end

  test "request a reset token for an unknown email" do
    conn = call(TestRouter, :post, "/password_resets", %{email: @email})
    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Forgot your password?")
    {:safe, escaped_html} = Phoenix.HTML.html_escape("We'll send you an email to reset your password")
    assert String.contains?(conn.resp_body, escaped_html)
  end

  test "request a reset token" do
    Registrator.changeset(%{"email" => @email, "password" => "oldpassword"})
                                      |> Ecto.Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
                                      |> repo.insert!

    conn = call(TestRouter, :post, "/password_resets", %{email: @email})

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Forgot your password?")
    {:safe, escaped_html} = Phoenix.HTML.html_escape("We'll send you an email to reset your password")
    assert String.contains?(conn.resp_body, escaped_html)

    user = repo.get_by!(Sentinel.User, email: @email)
    assert user.hashed_password_reset_token != nil
  end

  test "reset password with a wrong token" do
    {_reset_token, changeset} = Registrator.changeset(%{email: @email, password: "oldpassword"})
                                |> PasswordResetter.create_changeset
    user = repo.insert!(changeset)

    params = %{user_id: user.id, password_reset_token: "wrong_token", password: "newpassword"}
    conn = call(TestRouter, :post, "/password_resets/reset", params)
    assert conn.status == 422
    assert String.contains?(conn.resp_body, "Something went wrong. You may have taken too long to reset your password")
  end

  test "reset password" do
    {reset_token, changeset} = Registrator.changeset(%{email: @email, password: "oldpassword"})
                                |> PasswordResetter.create_changeset
    user = repo.insert!(changeset)

    params = %{user_id: user.id, password_reset_token: reset_token, password: "newpassword"}
    conn = call(TestRouter, :post, "/password_resets/reset", params)
    assert conn.status == 200
  end
end
