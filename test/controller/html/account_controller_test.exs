defmodule Html.AccountControllerTest do
  use Sentinel.TestCase
  use Plug.Test
  use Bamboo.Test, shared: true

  import Mock
  import HtmlRequestHelper
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

  setup do
    user = TestRepo.insert!(%User{
      email: @old_email,
      confirmed_at: Ecto.DateTime.utc,
      hashed_password: Util.crypto_provider.hashpwsalt(@old_password)
    })

    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end

    {:ok, %{user: user}}
  end

  test "get current user account info", %{user: user} do
    conn = call_with_session(user, TestRouter, :get, "/account", %{})
    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Edit Account")
  end

  test "update password", %{user: user} = context do
    conn = call_with_session(user, TestRouter, :put, "/account", %{account: %{password: @new_password}})
    assert conn.status == 200
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @new_password)

    assert String.contains?(conn.resp_body, "Account updated")
    refute_delivered_email Sentinel.Mailer.send_new_email_address_email(context.user, "token")
  end

  test "update email", %{user: user} = context do
    mocked_token = SecureRandom.urlsafe_base64()
    mocked_user = Map.merge(context.user, %{unconfirmed_email: @new_email})
    mocked_mail = Sentinel.Mailer.send_new_email_address_email(mocked_user, mocked_token)

    with_mock Sentinel.Mailer, [:passthrough], [send_new_email_address_email: fn(_, _) -> mocked_mail end] do
      conn = call_with_session(user, TestRouter, :put, "/account", %{account: %{email: @new_email}})
      assert conn.status == 200
      assert String.contains?(conn.resp_body, "Account updated")

      {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)

      assert mocked_mail.from == @from_email
      assert mocked_mail.to == @new_email
      assert mocked_mail.subject == "Please confirm your email address"
      assert_delivered_email mocked_mail
    end
  end

  test "set email to the same email it was before", %{user: user} = context do
    conn = call_with_session(user, TestRouter, :put, "/account", %{account: %{email: @old_email}})
    assert conn.status == 200
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)
    assert String.contains?(conn.resp_body, "Account updated")

    reloaded_user = TestRepo.get(User, context.user.id)
    assert reloaded_user.unconfirmed_email == nil

    refute_delivered_email Sentinel.Mailer.send_new_email_address_email(context.user, "token")
  end

  test "update account with custom validations", %{user: user} = context do
    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Ecto.Changeset.add_error(changeset, :password, "too_short")
    end)
    conn = call_with_session(user, TestRouter, :put, "/account", %{account: %{password: @new_password}})
    assert conn.status == 422
    assert String.contains?(conn.resp_body, "Failed to update account")
    {:ok, _} = Authenticator.authenticate_by_email(@old_email, @old_password)

    refute_delivered_email Sentinel.Mailer.send_new_email_address_email(context.user, "token")
  end
end
