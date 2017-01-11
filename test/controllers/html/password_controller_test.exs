defmodule Html.PasswordControllerTest do
  use Sentinel.ConnCase

  alias Ecto.Changeset
  alias Ecto.DateTime
  alias GuardianDb.Token
  alias Sentinel.Changeset.Registrator
  alias Sentinel.Changeset.PasswordResetter
  alias Sentinel.Ueberauthenticator

  @email "user@example.com"
  @new_password "new_password"

  setup do
    auth = Factory.insert(:ueberauth)
    user = auth.user
    permissions = User.permissions(user.id)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token, permissions)
    authenticated_conn =
      build_conn()
      |> Sentinel.ConnCase.conn_with_fetched_session
      |> put_session(Guardian.Keys.base_key(:default), token)
      |> Sentinel.ConnCase.run_plug(Guardian.Plug.VerifySession)
      |> Sentinel.ConnCase.run_plug(Guardian.Plug.LoadResource)

    {:ok, %{conn: build_conn(), user: user, auth: auth, authenticated_conn: authenticated_conn}}
  end

  test "request the password reset new page", %{conn: conn} do
    conn = get conn, password_path(conn, :new)
    response(conn, 200)

    assert String.contains?(conn.resp_body, "Forgot your password?")
  end

  test "request a reset token for an unknown email", %{conn: conn} do
    conn = post conn, password_path(conn, :create), %{email: @email}
    response(conn, 302)

    assert String.contains?(conn.private.phoenix_flash["info"],
      "You'll receive an email with instructions about how to reset your password in a few minutes. ")
    refute_delivered_email Sentinel.Mailer.PasswordReset.build(%User{email: @email}, "token")
  end

  test "request a reset token", %{conn: conn, user: user} do
    mocked_reset_token = "mocked_reset_token"
    mocked_mail = Mailer.send_password_reset_email(user, mocked_reset_token)

    with_mock Sentinel.Mailer, [:passthrough], [send_password_reset_email: fn(_, _) -> mocked_mail end] do
      conn = post conn, password_path(conn, :create), %{email: user.email}
      response(conn, 302)

      updated_auth = TestRepo.get_by!(Sentinel.Ueberauth, user_id: user.id, provider: "identity")
      assert updated_auth.hashed_password_reset_token != nil
      assert_delivered_email mocked_mail
    end
  end

  test "reset password with a wrong token", %{conn: conn, user: user, auth: auth} do
    {_reset_token, changeset} = auth |> PasswordResetter.create_changeset
    auth = TestRepo.update!(changeset)

    params = %{user_id: user.id, password_reset_token: "wrong_token", password: "newpassword"}
    conn = put conn, password_path(conn, :update), params
    response(conn, 422)

    assert String.contains?(conn.private.phoenix_flash["error"], "Unable to reset your password")
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.password_path(Sentinel.Config.endpoint, :new))
  end

  test "reset password without confirmation", %{conn: conn, user: user, auth: auth} do
    old_hashed_password = auth.hashed_password
    {reset_token, changeset} = auth |> PasswordResetter.create_changeset
    TestRepo.update!(changeset)

    params = %{user_id: user.id, password_reset_token: reset_token, password: @new_password}
    conn = put conn, password_path(conn, :update), params
    response(conn, 422)

    assert String.contains?(conn.private.phoenix_flash["error"], "Unable to reset your password")
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.password_path(Sentinel.Config.endpoint, :new))
  end

  test "reset password with confirmation", %{conn: conn, user: user, auth: auth} do #FIXME FAILING
    old_hashed_password = auth.hashed_password
    {reset_token, changeset} = auth |> PasswordResetter.create_changeset
    TestRepo.update!(changeset)
    token_count = length(TestRepo.all(Token))

    params = %{user_id: user.id, password_reset_token: reset_token, password: @new_password, password_confirmation: @new_password}
    conn = put conn, password_path(conn, :update), params
    response(conn, 302)

    assert String.contains?(conn.private.phoenix_flash["info"], "Successfully updated password")
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.account_path(Sentinel.Config.endpoint, :edit))

    updated_auth = TestRepo.get!(Sentinel.Ueberauth, auth.id)

    refute updated_auth.hashed_password == old_hashed_password
    assert (token_count + 1) == length(TestRepo.all(Token))
  end

  test "Reset password when logged in", %{authenticated_conn: conn, user: user, auth: auth} do #FIXME FAILING
    old_hashed_password = auth.hashed_password
    user
    |> Sentinel.User.changeset(%{confirmed_at: Ecto.DateTime.utc})
    |> TestRepo.update!

    conn = put conn, password_path(conn, :authenticated_update), %{account: %{password: @new_password, password_confirmation: @new_password}}
    response = response(conn, 302)

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
    assert String.contains?(conn.private.phoenix_flash["info"], "Update successful")
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.account_path(Sentinel.Config.endpoint, :edit))
  end
end
