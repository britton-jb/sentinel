defmodule Json.PasswordControllerTest do
  use Sentinel.ConnCase

  alias GuardianDb.Token
  alias Sentinel.Changeset.PasswordResetter
  alias Sentinel.Ueberauthenticator

  @email "user@example.com"
  @new_password "new_password"

  setup do
    conn =
      build_conn()
      |> Conn.put_req_header("content-type", "application/json")
      |> Conn.put_req_header("accept", "application/json")
    auth = Factory.insert(:ueberauth)
    user = auth.user
    {:ok, token, _} = Sentinel.Guardian.encode_and_sign(user)
    authenticated_conn = conn |> Conn.put_req_header("authorization", "Bearer #{token}")

    {:ok, %{conn: conn, user: user, auth: auth, authenticated_conn: authenticated_conn}}
  end

  test "request a reset token for an unknown email", %{conn: conn} do
    conn = get conn, api_password_path(conn, :new), %{email: @email}
    response = json_response(conn, 200)
    assert response == "ok"
    refute_delivered_email Sentinel.Mailer.PasswordReset.build(%User{email: @email}, "token")
  end

  test "request a reset token", %{conn: conn, user: user} do
    mocked_reset_token = "mocked_reset_token"
    mocked_mail = Mailer.PasswordReset.build(user, mocked_reset_token)

    with_mock Mailer.PasswordReset, [:passthrough], [build: fn(_, _) -> mocked_mail end] do
      conn = get conn, api_password_path(conn, :new), %{email: user.email}
      response = json_response(conn, 200)
      assert response == "ok"

      updated_auth = TestRepo.get_by!(Sentinel.Ueberauth, user_id: user.id, provider: "identity")
      assert updated_auth.hashed_password_reset_token != nil
      assert_delivered_email mocked_mail
    end
  end

  test "reset password with a wrong token", %{conn: conn, user: user, auth: auth} do
    {_reset_token, changeset} = auth |> PasswordResetter.create_changeset
    TestRepo.update!(changeset)

    params = %{user_id: user.id, password_reset_token: "wrong_token", password: "newpassword"}
    conn = put conn, api_password_path(conn, :update), params
    response = json_response(conn, 422)

    assert response == %{"errors" => [%{"password_confirmation" => "mismatch"}, %{"password_reset_token" => "invalid"}]}
  end

  test "reset password without confirmation", %{conn: conn, user: user, auth: auth} do
    {reset_token, changeset} = auth |> PasswordResetter.create_changeset
    TestRepo.update!(changeset)

    params = %{user_id: user.id, password_reset_token: reset_token, password: @new_password}
    conn = put conn, api_password_path(conn, :update), params
    response = json_response(conn, 422)
    assert response == %{"errors" => [%{"password_confirmation" => "mismatch"}]}
  end

  test "reset password with confirmation", %{conn: conn, user: user, auth: auth} do
    old_hashed_password = auth.hashed_password
    {reset_token, changeset} = auth |> PasswordResetter.create_changeset
    TestRepo.update!(changeset)

    params = %{user_id: user.id, password_reset_token: reset_token, password: @new_password, password_confirmation: @new_password}
    conn = put conn, api_password_path(conn, :update), params
    assert %{"token" => session_token} = json_response(conn, 200)
    assert TestRepo.get_by!(Token, jwt: session_token)
    updated_auth = TestRepo.get!(Sentinel.Ueberauth, auth.id)
    refute updated_auth.hashed_password == old_hashed_password
  end

  test "reset password when logged in", %{authenticated_conn: conn, user: user, auth: auth} do
    old_hashed_password = auth.hashed_password
    user
    |> Sentinel.User.changeset(%{confirmed_at: DateTime.utc_now()})
    |> TestRepo.update!

    conn = put conn, api_password_path(conn, :authenticated_update), %{account: %{password: @new_password, password_confirmation: @new_password}}
    json_response(conn, 200)

    updated_auth = TestRepo.get!(Sentinel.Ueberauth, auth.id)
    refute updated_auth.hashed_password == old_hashed_password

    {:ok, _} = Ueberauthenticator.ueberauthenticate(%Ueberauth.Auth{
      provider: :identity,
      uid: user.email,
      credentials: %Ueberauth.Auth.Credentials{
        other: %{password: @new_password}
      }
    })
    refute_delivered_email Sentinel.Mailer.NewEmailAddress.build(user, "token")
  end
end
