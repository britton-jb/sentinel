defmodule Html.UnlockControllerTest do
  use Sentinel.ConnCase

  setup do
    auth = Factory.insert(:ueberauth, locked_at: DateTime.utc_now(), unlock_token: "unlock_token")
    mocked_mail = Mailer.Unlock.build(auth.user, auth.unlock_token)

    {:ok, %{conn: build_conn(), auth: auth, mocked_mail: mocked_mail}}
  end

  test "render resend unlock email page", %{conn: conn} do
    conn = get conn, unlock_path(conn, :new)
    assert response(conn, 200)
  end

  test "resend unlock email", %{conn: conn, auth: auth, mocked_mail: mocked_mail} do
    with_mock Mailer.Unlock, [:passthrough], [build: fn(_, _) -> mocked_mail end] do
      conn = post conn, unlock_path(conn, :create), %{unlock: %{email: auth.user.email}}
      assert response(conn, 302)   
      assert_delivered_email mocked_mail      
    end      
  end

  test "unlock account", %{conn: conn, auth: auth} do
    conn = put conn, unlock_path(conn, :update), %{unlock_token: auth.unlock_token}
    assert response(conn, 302)
    
    updated_auth = TestRepo.get(Sentinel.Ueberauth, auth.id)
    
    assert updated_auth.locked_at == nil
    assert updated_auth.unlock_token == nil    
  end
end