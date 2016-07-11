defmodule Html.UserControllerTest do
  use Sentinel.TestCase
  use Plug.Test
  use Bamboo.Test, shared: true

  import Mock
  import RouterHelper
  alias Sentinel.Registrator
  alias Sentinel.PasswordResetter
  alias Sentinel.Confirmator
  alias Sentinel.TestRouter
  alias Sentinel.TestRepo
  alias Sentinel.User
  alias Sentinel.UserHelper
  alias Mix.Config
  import Sentinel.Util

  @email "user@example.com"
  @password "secret"
  @from_email "test@example.com"

  defp app_name do
    Application.get_env(:sentinel, :app_name)
  end

  setup do
    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end
  end

  test "default sign up" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: false]])

    mocked_token = SecureRandom.urlsafe_base64()
    mocked_mail = Sentinel.Mailer.send_welcome_email(%{unconfirmed_email: @email, email: @email}, mocked_token)

    with_mock Sentinel.Mailer, [:passthrough], [send_welcome_email: fn(_, _) -> mocked_mail end] do
      conn = call(TestRouter, :post, "/users", %{user: %{password: @password, email: @email}})
      assert conn.status == 201
      assert conn.private.phoenix_flash == %{"info" => "Successfully logged in. Please confirm your account"}

      user = TestRepo.get_by!(User, email: @email)
      refute is_nil(user.hashed_confirmation_token)

      assert mocked_mail.from == @from_email
      assert mocked_mail.to == @email
      assert mocked_mail.subject == "Hello #{@email}"
      assert_delivered_email mocked_mail
    end
  end

  test "confirmable :required sign up" do
    Config.persist([sentinel: [confirmable: :required]])
    Config.persist([sentinel: [invitable: false]])

    mocked_token = SecureRandom.urlsafe_base64()
    mocked_mail = Sentinel.Mailer.send_welcome_email(%{unconfirmed_email: @email, email: @email}, mocked_token)

    with_mock Sentinel.Mailer, [:passthrough], [send_welcome_email: fn(_, _) -> mocked_mail end] do
      conn = call(TestRouter, :post, "/users", %{user: %{password: @password, email: @email}})
      assert conn.status == 201
      assert conn.private.phoenix_flash == %{"info" => "Successfully created account. Please confirm your account"}

      user = TestRepo.get_by!(User, email: @email)
      refute is_nil(user.hashed_confirmation_token)

      assert mocked_mail.from == @from_email
      assert mocked_mail.to == @email
      assert mocked_mail.subject == "Hello #{@email}"
      assert_delivered_email mocked_mail
    end
  end

  test "confirmable :false sign up" do
    Config.persist([sentinel: [confirmable: false]])
    Config.persist([sentinel: [invitable: false]])

    conn = call(TestRouter, :post, "/users", %{user: %{password: @password, email: @email}})
    assert conn.status == 201
    assert conn.private.phoenix_flash == %{"info" => "Successfully logged in"}

    user = TestRepo.get_by!(User, email: @email)
    refute is_nil(user.hashed_confirmation_token)
    refute_delivered_email Sentinel.Mailer.send_new_email_address_email(user, "token")
  end

  test "invitable sign up" do
    Config.persist([sentinel: [invitable: true]])
    Config.persist([sentinel: [confirmable: false]])

    mocked_confirmation_token = SecureRandom.urlsafe_base64()
    mocked_password_reset_token = SecureRandom.urlsafe_base64()
    mocked_mail = Sentinel.Mailer.send_invite_email(%{email: @email}, {mocked_confirmation_token, mocked_password_reset_token})

    with_mock Sentinel.Mailer, [:passthrough], [send_invite_email: fn(_, _) -> mocked_mail end] do
      conn = call(TestRouter, :post, "/users", %{user: %{email: @email}})
      assert conn.status == 201
      assert conn.private.phoenix_flash == %{"info" => "Successfully invited the user"}

      assert mocked_mail.from == @from_email
      assert mocked_mail.to == @email
      assert mocked_mail.subject == "You've been invited to #{app_name} #{@email}"
      assert_delivered_email mocked_mail
    end
  end

  test "invitable and confirmable sign up" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: true]])

    mocked_confirmation_token = SecureRandom.urlsafe_base64()
    mocked_password_reset_token = SecureRandom.urlsafe_base64()
    mocked_mail = Sentinel.Mailer.send_invite_email(%{email: @email}, {mocked_confirmation_token, mocked_password_reset_token})

    with_mock Sentinel.Mailer, [:passthrough], [send_invite_email: fn(_, _) -> mocked_mail end] do
      conn = call(TestRouter, :post, "/users", %{user: %{email: @email}})
      assert conn.status == 201
      assert conn.private.phoenix_flash == %{"info" => "Successfully invited the user"}

      assert mocked_mail.from == @from_email
      assert mocked_mail.to == @email
      assert mocked_mail.subject == "You've been invited to #{app_name} #{@email}"
      assert_delivered_email mocked_mail
    end
  end

  test "invitable setup password" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: true]])

    {confirmation_token, changeset} = Registrator.changeset(%{email: @email})
                                      |> Confirmator.confirmation_needed_changeset
    user = repo.insert!(changeset)

    {password_reset_token, changeset} = PasswordResetter.create_changeset(user)
    user = repo.update!(changeset)

    conn = call(TestRouter, :post, "/users/#{user.id}/invited", %{confirmation_token: confirmation_token, password_reset_token: password_reset_token, password: @password})
    assert conn.status == 201
    assert conn.private.phoenix_flash == %{"info" => "Successfully setup your account"}

    updated_user = repo.get! UserHelper.model, user.id

    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.hashed_password_reset_token == nil
    assert updated_user.unconfirmed_email == nil
  end

  test "sign up with missing password without the invitable module enabled" do
    Config.persist([sentinel: [invitable: false]])

    conn = call(TestRouter, :post, "/users", %{user: %{email: @email}})
    assert conn.status == 422
    assert String.contains?(conn.resp_body, "Unable to complete the registration")
  end

  test "sign up with missing email" do
    conn = call(TestRouter, :post, "/users", %{"user" => %{"password" => @password}})
    assert conn.status == 422
    assert String.contains?(conn.resp_body, "Unable to complete the registration")
  end

  test "sign up with custom validations" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: false]])

    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Ecto.Changeset.add_error(changeset, :password, "too short")
    end)
    conn = call(TestRouter, :post, "/users", %{user: %{email: @email, password: @password}})
    assert conn.status == 422
    assert String.contains?(conn.resp_body, "Unable to complete the registration")
  end
end
