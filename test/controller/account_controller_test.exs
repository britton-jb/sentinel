defmodule AccountControllerTest do
  use Sentinel.Case
  use Plug.Test

  import RouterHelper
  alias Sentinel.TestRouter
  alias Sentinel.TestRepo
  alias Sentinel.User
  alias Sentinel.Authenticator
  alias Sentinel.Util

  @from_email "test@example.com"
  @old_email "old@example.com"
  @new_email "user@example.com"
  @old_password "old_secret"
  @new_password "secret"
  @headers [{"content-type", "application/json"}]

  setup_all do
    Mailman.TestServer.start
    :ok
  end

  setup do
    Mailman.TestServer.clear_deliveries

    user = TestRepo.insert!(%User{
      email: @old_email,
      confirmed_at: Ecto.DateTime.utc,
      hashed_password: Util.crypto_provider.hashpwsalt(@old_password)
    })
    permissions = User.permissions(user.role)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token, permissions)
    headers = [{"authorization", token} | @headers]

    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end

    {:ok, %{user: user, headers: headers}}
  end

  test "update password", context do
    conn = call(TestRouter, :put, "/api/account", %{account: %{password: @new_password}}, context.headers)
    assert conn.status == 200
    assert conn.resp_body == Poison.encode!("ok")
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @new_password)

    assert length(Mailman.TestServer.deliveries) == 0
  end

  test "update email", context do
    conn = call(TestRouter, :put, "/api/account", %{account: %{email: @new_email}}, context.headers)
    assert conn.status == 200
    assert conn.resp_body == Poison.encode!("ok")
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)
    assert TestRepo.one(User).unconfirmed_email == @new_email

    mail =  Mailman.TestServer.deliveries |> List.last |> Mailman.Email.parse!
    assert mail.from == @from_email
    assert mail.to == ["User <#{@new_email}>"]
    assert mail.subject == "Please confirm your email address"
  end

  test "set email to the same email it was before", context do
    conn = call(TestRouter, :put, "/api/account", %{account: %{email: @old_email}}, context.headers)
    assert conn.status == 200
    assert conn.resp_body == Poison.encode!("ok")
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)
    assert TestRepo.one(User).unconfirmed_email == nil

    assert length(Mailman.TestServer.deliveries) == 0
  end

  test "update account with custom validations", context do
    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Ecto.Changeset.add_error(changeset, :password, "too_short")
    end)
    conn = call(TestRouter, :put, "/api/account", %{account: %{password: @new_password}}, context.headers)
    assert conn.status == 422
    assert conn.resp_body == Poison.encode!(%{errors: %{password: :too_short}})
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)

    assert length(Mailman.TestServer.deliveries) == 0
  end
end
