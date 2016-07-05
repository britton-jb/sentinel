defmodule Json.AccountControllerTest do
  use Sentinel.TestCase
  use Plug.Test
  use Bamboo.Test, shared: true

  import Mock
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

  setup do
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

  test "get current user account info", context do
    conn = call(TestRouter, :get, "/api/account", %{}, context.headers)
    assert conn.status == 200
    assert Poison.decode!(conn.resp_body)["email"] == @old_email
  end

  test "update password", context do
    conn = call(TestRouter, :put, "/api/account", %{account: %{password: @new_password}}, context.headers)
    assert conn.status == 200
    assert Poison.decode!(conn.resp_body)["hashed_password"] != context.user.hashed_password
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @new_password)

    refute_delivered_email Sentinel.Mailer.send_new_email_address_email(context.user, "token")
  end

  test "update email", context do
    mocked_token = SecureRandom.urlsafe_base64()
    mocked_user = Map.merge(context.user, %{unconfirmed_email: @new_email})
    mocked_mail = Sentinel.Mailer.send_new_email_address_email(mocked_user, mocked_token)

    with_mock Sentinel.Mailer, [:passthrough], [send_new_email_address_email: fn(_, _) -> mocked_mail end] do
      conn = call(TestRouter, :put, "/api/account", %{account: %{email: @new_email}}, context.headers)
      assert conn.status == 200
      assert Poison.decode!(conn.resp_body)["email"] == @old_email
      assert Poison.decode!(conn.resp_body)["unconfirmed_email"] == @new_email
      {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)

      assert mocked_mail.from == @from_email
      assert mocked_mail.to == @new_email
      assert mocked_mail.subject == "Please confirm your email address"
      assert_delivered_email mocked_mail
    end
  end

  test "set email to the same email it was before", context do
    conn = call(TestRouter, :put, "/api/account", %{account: %{email: @old_email}}, context.headers)
    assert conn.status == 200
    assert Poison.decode!(conn.resp_body)["email"] == @old_email
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)

    reloaded_user = TestRepo.get(User, context.user.id)
    assert reloaded_user.unconfirmed_email == nil

    refute_delivered_email Sentinel.Mailer.send_new_email_address_email(context.user, "token")
  end

  test "update account with custom validations", context do
    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Ecto.Changeset.add_error(changeset, :password, "too_short")
    end)
    conn = call(TestRouter, :put, "/api/account", %{account: %{password: @new_password}}, context.headers)
    assert conn.status == 422
    assert conn.resp_body == Poison.encode!(%{errors: [%{password: :too_short}]})
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)

    refute_delivered_email Sentinel.Mailer.send_new_email_address_email(context.user, "token")
  end
end
