defmodule Json.AuthControllerTest do
  use Sentinel.ConnCase

  alias GuardianDb.Token
  alias Mix.Config

  @unknown_email "unknown_email@example.com"
  @password "secret"

  setup do
    conn =
      build_conn()
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("accept", "application/json")
    auth = Factory.insert(:ueberauth)
    user = auth.user

    on_exit fn ->
      Config.persist([sentinel: [confirmable: :optional]])
      Config.persist([sentinel: [invitable: true]])
    end

    mocked_mail = Mailer.Unlock.build(auth.user, auth.unlock_token)
    params = %{user: %{email: user.email, password: auth.plain_text_password}}
    {:ok, %{conn: conn, params: params, auth: auth, mocked_mail: mocked_mail}}
  end

  test "sign in with unknown email", %{conn: conn} do
    conn = post conn, auth_path(conn, :create), %{user: %{email: @unknown_email, password: @password}}
    response = json_response(conn, 401)
    assert response == %{"errors" => [%{"base" => "Unknown email or password"}]}
  end

  test "sign in with wrong password", %{conn: conn, params: params} do
    conn = post conn, auth_path(conn, :create), %{user: %{password: "wrong", email: params.user.email}}
    response = json_response(conn, 401)
    assert response == %{"errors" => [%{"base" => "Unknown email or password"}]}
  end

  test "sign in as unconfirmed user - confirmable default/optional", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :optional]])

    conn = post conn, auth_path(conn, :create), params
    assert %{"token" => token} = json_response(conn, 200)
    TestRepo.get_by!(Token, jwt: token)
  end

  test "sign in as unconfirmed user - confirmable false", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :false]])

    conn = post conn, auth_path(conn, :create), params
    assert %{"token" => token} = json_response(conn, 200)
    TestRepo.get_by!(Token, jwt: token)
  end

  test "sign in as unconfirmed user - confirmable required", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :required]])

    conn = post conn, auth_path(conn, :create), params
    response = json_response(conn, 401)
    assert response == %{"errors" => [%{"base" => "Account not confirmed yet. Please follow the instructions we sent you by email."}]}
  end

  test "sign in as confirmed user with email", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :required]])

    Sentinel.User
    |> TestRepo.get_by(email: params.user.email)
    |> Sentinel.User.changeset(%{confirmed_at: DateTime.utc_now(), hashed_confirmation_token: nil})
    |> TestRepo.update!

    conn = post conn, auth_path(conn, :create), params
    assert %{"token" => token} = json_response(conn, 200)
    TestRepo.get_by!(Token, jwt: token)
  end

  test "sign in as confirmed user with email - case insensitive", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :required]])

    Sentinel.User
    |> TestRepo.get_by(email: params.user.email)
    |> Sentinel.User.changeset(%{confirmed_at: DateTime.utc_now(), hashed_confirmation_token: nil})
    |> TestRepo.update!

    conn = post conn, auth_path(conn, :create), %{
      user: %{
        email: String.upcase(params.user.email),
        password: params.user.password
      }
    }
    assert %{"token" => token} = json_response(conn, 200)
    TestRepo.get_by!(Token, jwt: token)
  end

  test "lockable sign in with locked account", %{conn: conn, params: params, auth: auth} do
    Config.persist([sentinel: [lockable: true]])

    auth
    |> Sentinel.Ueberauth.changeset(%{locked_at: DateTime.utc_now()})
    |> TestRepo.update!

    conn = post conn, auth_path(conn, :create), params
    response = json_response(conn, 401)
    assert response == %{"errors" => [%{"lockable" => "Your account is currently locked. Please follow the instructions we sent you by email to unlock it."}]}
  end

  test "lockable on 4rth attempt notifies user of single remaining attempt", %{conn: conn, params: params, auth: auth} do
    Config.persist([sentinel: [lockable: true]])

    auth
    |> Sentinel.Ueberauth.changeset(%{failed_attempts: 3})
    |> TestRepo.update!

    conn = post conn, auth_path(conn, :create), %{user: %{password: "wrong", email: params.user.email}}
    response = json_response(conn, 401)
    assert response == %{"errors" => [%{"lockable" => "You have one more attempt to authenticate correctly before this account is locked."}]}
  end

  test "lockable on 5th attempt notifies user of lock", %{conn: conn, params: params, auth: auth, mocked_mail: mocked_mail} do
    Config.persist([sentinel: [lockable: true]])

    auth
    |> Sentinel.Ueberauth.changeset(%{failed_attempts: 4})
    |> TestRepo.update!

    with_mock Mailer.Unlock, [:passthrough], [build: fn(_, _) -> mocked_mail end] do
      conn = post conn, auth_path(conn, :create), %{user: %{password: "wrong", email: params.user.email}}
      response = json_response(conn, 401)
      assert_delivered_email mocked_mail

      assert response == %{"errors" => [%{"lockable" => "Your account has been locked. We've sent you email instructions regarding how to unlock it."}]}
    end
  end

  test "sign out", %{conn: conn} do
    user = Factory.insert(:user, confirmed_at: DateTime.utc_now())
    {:ok, token, _} = Sentinel.Guardian.encode_and_sign(user)

    token_count = length(TestRepo.all(Token))
    conn = conn |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
    conn = delete conn, "/auth/session"

    assert json_response(conn, 200)
    assert (token_count - 1) == length(TestRepo.all(Token))
  end
end
