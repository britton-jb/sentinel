defmodule ResetPasswordControllerTest do
  use Sentinel.Case
  use Plug.Test
  import RouterHelper
  alias Sentinel.TestRouter
  alias Sentinel.Registrator
  alias Sentinel.PasswordResetter
  import Sentinel.Util
  alias Sentinel.UserHelper

  @email "user@example.com"
  @headers [{"content-type", "application/json"}]

  setup_all do
    Mailman.TestServer.start
    :ok
  end

  test "request a reset token for an unknown email" do
    conn = call(TestRouter, :post, "/api/password_resets", %{email: @email}, @headers)
    assert conn.status == 422
    assert conn.resp_body == Poison.encode!(%{errors: %{email: "not known"}})
  end

  test "request a reset token" do
    Registrator.changeset(%{"email" => @email, "password" => "oldpassword"})
                                      |> Ecto.Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
                                      |> repo.insert!

    conn = call(TestRouter, :post, "/api/password_resets", %{email: @email}, @headers)

    assert conn.status == 200
    assert Poison.decode!(conn.resp_body) == "ok"

    user = repo.one UserHelper.model
    assert user.hashed_password_reset_token != nil
  end

  test "reset password with a wrong token" do
    {_reset_token, changeset} = Registrator.changeset(%{email: @email, password: "oldpassword"})
                                |> PasswordResetter.create_changeset
    user = repo.insert!(changeset)

    params = %{user_id: user.id, password_reset_token: "wrong_token", password: "newpassword"}
    conn = call(TestRouter, :post, "/api/password_resets/reset", params, @headers)
    assert conn.status == 422
    assert conn.resp_body == Poison.encode!(%{errors: %{password_reset_token: :invalid}})
  end

  test "reset password" do
    {reset_token, changeset} = Registrator.changeset(%{email: @email, password: "oldpassword"})
                                |> PasswordResetter.create_changeset
    user = repo.insert!(changeset)

    params = %{user_id: user.id, password_reset_token: reset_token, password: "newpassword"}
    conn = call(TestRouter, :post, "/api/password_resets/reset", params, @headers)
    assert conn.status == 200

    session_token = Poison.decode!(conn.resp_body)
                 |> Dict.fetch!("token")

    assert session_token == repo.one(GuardianDb.Token).jwt
  end
end
