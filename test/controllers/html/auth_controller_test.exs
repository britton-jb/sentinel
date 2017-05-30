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

    params = %{session: %{email: user.email, password: auth.plain_text_password}}
    {:ok, %{conn: build_conn(), params: params}}
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
    assert String.contains?(conn.private.phoenix_flash["error"], "Unknown username or password")
  end

  test "sign in with wrong password", %{conn: conn, params: params} do
    conn = post conn, auth_path(conn, :create), %{session: %{password: "wrong", email: params.session.email}}
    response(conn, 302)
    assert String.contains?(conn.resp_body, Sentinel.Config.router_helper.auth_path(Sentinel.Config.endpoint, :new))
    assert String.contains?(conn.private.phoenix_flash["error"], "Unknown username or password")
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
    assert String.contains?(conn.private.phoenix_flash["error"], "Unknown username or password")
  end

  test "sign in as confirmed user with email", %{conn: conn, params: params} do
    Config.persist([sentinel: [confirmable: :required]])
    token_count = length(TestRepo.all(Token))

    Sentinel.User
    |> TestRepo.get_by(email: params.session.email)
    |> Sentinel.User.changeset(%{confirmed_at: Ecto.DateTime.utc, hashed_confirmation_token: nil})
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
    |> Sentinel.User.changeset(%{confirmed_at: Ecto.DateTime.utc, hashed_confirmation_token: nil})
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

  test "sign out", %{conn: conn} do
    user = Factory.insert(:user, confirmed_at: Ecto.DateTime.utc)
    permissions = Sentinel.User.permissions(user.role)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token, permissions)

    conn =
      conn
      |> Sentinel.ConnCase.conn_with_fetched_session
      |> put_session(Guardian.Keys.base_key(:default), token)
      |> Sentinel.ConnCase.run_plug(Guardian.Plug.VerifySession)
      |> Sentinel.ConnCase.run_plug(Guardian.Plug.LoadResource)

    conn = delete conn, "/auth/session"

    response(conn, 302)
    assert String.contains?(conn.resp_body, "a href=\"/\"")
  end
end