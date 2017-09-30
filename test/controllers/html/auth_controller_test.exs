defmodule Html.AuthControllerTest do
  use Sentinel.ConnCase

  alias GuardianDb.Token
  alias Mix.Config

  @unknown_email "unknown_email@example.com"
  @password "secret"

  setup do
    auth = Factory.insert(:ueberauth)
    user = auth.user

    on_exit fn ->
      Config.persist([sentinel: [confirmable: :optional]])
      Config.persist([sentinel: [invitable: true]])
    end

    mocked_mail = Mailer.Unlock.build(auth.user, auth.unlock_token)
    params = %{session: %{email: user.email, password: auth.plain_text_password}}
    {:ok, %{conn: build_conn(), params: params, auth: auth, mocked_mail: mocked_mail}}
  end

  test "get new session page", %{conn: conn} do
    conn = get conn, auth_path(conn, :new)
    response(conn, 200)
    assert String.contains?(conn.resp_body, "Login")
  end

  test "session page renders ueberauth provider links", %{conn: conn} do
    conn = get conn, auth_path(conn, :new)
    response(conn, 200)
    assert String.contains?(conn.resp_body, "Or login with one of the following")
  end

  test "sign in with unknown email", %{conn: conn} do
    conn = post conn, auth_path(conn, :create), %{session: %{email: @unknown_email, password: @password}}
    response(conn, 302)
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.auth_path(Sentinel.Config.endpoint, :new))
    assert String.contains?(conn.private.phoenix_flash["error"], "Unknown email or password")
  end

  test "sign in with wrong password", %{conn: conn, params: params} do
    conn = post conn, auth_path(conn, :create), %{session: %{password: "wrong", email: params.session.email}}
    response(conn, 302)
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.auth_path(Sentinel.Config.endpoint, :new))
    assert String.contains?(conn.private.phoenix_flash["error"], "Unknown email or password")
  end

  test "sign in as unconfirmed user - confirmable default/optional", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :optional]])
    token_count = length(TestRepo.all(Token))

    conn = post conn, auth_path(conn, :create), params
    response(conn, 302)
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.account_path(Sentinel.Config.endpoint, :edit))
    assert String.contains?(conn.private.phoenix_flash["info"], "Logged in")
    assert (token_count + 1) == length(TestRepo.all(Token))
  end

  test "sign in as unconfirmed user - confirmable false", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :false]])
    token_count = length(TestRepo.all(Token))

    conn = post conn, auth_path(conn, :create), params
    response(conn, 302)
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.account_path(Sentinel.Config.endpoint, :edit))
    assert String.contains?(conn.private.phoenix_flash["info"], "Logged in")
    assert (token_count + 1) == length(TestRepo.all(Token))
  end

  test "sign in as unconfirmed user - confirmable required", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :required]])

    conn = post conn, auth_path(conn, :create), params
    response(conn, 302)    
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.auth_path(Sentinel.Config.endpoint, :new))
    assert String.contains?(conn.private.phoenix_flash["error"], "Account not confirmed yet. Please follow the instructions we sent you by email.")
  end

  test "sign in as confirmed user with email", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :required]])
    token_count = length(TestRepo.all(Token))

    Sentinel.User
    |> TestRepo.get_by(email: params.session.email)
    |> Sentinel.User.changeset(%{confirmed_at: DateTime.utc_now(), hashed_confirmation_token: nil})
    |> TestRepo.update!

    conn = post conn, auth_path(conn, :create), params
    response(conn, 302)

    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.account_path(Sentinel.Config.endpoint, :edit))
    assert (token_count + 1) == length(TestRepo.all(Token))
  end

  test "sign in as confirmed user with email - case insensitive", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :required]])
    token_count = length(TestRepo.all(Token))

    Sentinel.User
    |> TestRepo.get_by(email: params.session.email)
    |> Sentinel.User.changeset(%{confirmed_at: DateTime.utc_now(), hashed_confirmation_token: nil})
    |> TestRepo.update!

    conn = post conn, auth_path(conn, :create), %{
      session: %{
        email: String.upcase(params.session.email),
        password: params.session.password
      }
    }
    response(conn, 302)

    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.account_path(Sentinel.Config.endpoint, :edit))
    assert String.contains?(conn.private.phoenix_flash["info"], "Logged in")
    assert (token_count + 1) == length(TestRepo.all(Token))
  end

  test "sign in with locked account", %{conn: conn, params: params, auth: auth} do
    Config.persist([sentinel: [lockable: true]])
    auth
    |> Sentinel.Ueberauth.changeset(%{locked_at: DateTime.utc_now()})
    |> TestRepo.update!
    token_count = length(TestRepo.all(Token))

    conn = post conn, auth_path(conn, :create), params
    response(conn, 302)    
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.auth_path(Sentinel.Config.endpoint, :new))
    assert String.contains?(conn.private.phoenix_flash["error"], "Your account is currently locked. Please follow the instructions we sent you by email to unlock it.")
    assert (token_count) == length(TestRepo.all(Token))
  end

  test "lockable on 4rth attempt notifies user of single remaining attempt", %{conn: conn, params: params, auth: auth} do
    Config.persist([sentinel: [lockable: true]])
    auth
    |> Sentinel.Ueberauth.changeset(%{failed_attempts: 3})
    |> TestRepo.update!
    token_count = length(TestRepo.all(Token))

    conn = post conn, auth_path(conn, :create), %{session: %{password: "wrong", email: params.session.email}}
    response(conn, 302)
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.auth_path(Sentinel.Config.endpoint, :new))
    assert String.contains?(conn.private.phoenix_flash["error"], "You have one more attempt to authenticate correctly before this account is locked.")
    assert (token_count) == length(TestRepo.all(Token))
  end

  test "lockable on 5th attempt notifies user of lock", %{conn: conn, params: params, auth: auth, mocked_mail: mocked_mail} do
    Config.persist([sentinel: [lockable: true]])
    auth
    |> Sentinel.Ueberauth.changeset(%{failed_attempts: 4})
    |> TestRepo.update!
    token_count = length(TestRepo.all(Token))

    with_mock Mailer.Unlock, [:passthrough], [build: fn(_, _) -> mocked_mail end] do
      conn = post conn, auth_path(conn, :create), %{session: %{password: "wrong", email: params.session.email}}
      response(conn, 302)
      assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.auth_path(Sentinel.Config.endpoint, :new))
      assert String.contains?(conn.private.phoenix_flash["error"], "Your account has been locked. We've sent you email instructions regarding how to unlock it.")
      assert_delivered_email mocked_mail
    end

    assert (token_count) == length(TestRepo.all(Token))
  end

  test "sign out" do
    user = Factory.insert(:user, confirmed_at: DateTime.utc_now())
    {:ok, token, claims} = Sentinel.Guardian.encode_and_sign(user)

    conn =
      build_conn()
      |> init_test_session(%{guardian_default_token: token})
      |> Sentinel.Guardian.Plug.put_current_token(token)
      |> Sentinel.Guardian.Plug.put_current_claims(claims)

    conn = delete conn, "/auth/session"

    response(conn, 302)
    assert String.contains?(conn.resp_body, "a href=\"/\"")
  end
end
