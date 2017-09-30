defmodule Json.UnlockControllerTest do
  use Sentinel.ConnCase

  alias Sentinel.Mailer

  setup do
    conn =
      build_conn()
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("accept", "application/json")
    auth = Factory.insert(:ueberauth, locked_at: DateTime.utc_now(), unlock_token: "unlock_token")

    {:ok, %{conn: conn, auth: auth}}
  end

  test "resend unlock email", %{conn: conn, auth: auth} do
    mocked_mail = Mailer.Unlock.build(auth.user, auth.unlock_token)

    with_mock Mailer.Unlock, [:passthrough], [build: fn(_, _) -> mocked_mail end] do
      conn = post conn, api_unlock_path(conn, :create), %{email: auth.user.email}
      response = json_response(conn, 200)
      assert response == "ok"
      assert_delivered_email mocked_mail
    end
  end

  test "unlock account", %{conn: conn, auth: auth} do
    conn = put conn, api_unlock_path(conn, :update), %{unlock_token: auth.unlock_token}
    assert response(conn, 302)
    
    updated_auth = TestRepo.get(Sentinel.Ueberauth, auth.id)
    
    assert updated_auth.locked_at == nil
    assert updated_auth.unlock_token == nil    
  end
end
