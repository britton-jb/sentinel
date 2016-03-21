defmodule UserControllerTest do
  use Sentinel.Case
  use Plug.Test

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
  @headers [{"content-type", "application/json"}, {"language", "en"}]

  setup_all do
    Mailman.TestServer.start
    :ok
  end

  setup do
    Mailman.TestServer.clear_deliveries

    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end
  end

  test "default sign up" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: false]])

    conn = call(TestRouter, :post, "/api/users", %{user: %{password: @password, email: @email}}, @headers)
    assert conn.status == 201
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token

    user = TestRepo.one User
    assert user.email == @email
    assert !is_nil(user.hashed_confirmation_token)

    mail =  Mailman.TestServer.deliveries |> List.last |> Mailman.Email.parse!

    assert mail.from == "test@example.com"
    assert mail.to == ["User <#{@email}>"]
    assert mail.subject == "Hello " <> @email
    assert mail.text == "Hello user@example.com!\n\nWelcome to Test App\n\n"
  end

  test "confirmable :required sign up" do
    Config.persist([sentinel: [confirmable: :required]])
    Config.persist([sentinel: [invitable: false]])

    conn = call(TestRouter, :post, "/api/users", %{user: %{password: @password, email: @email}}, @headers)
    assert conn.status == 201
    assert conn.resp_body == Poison.encode!("ok")

    user = TestRepo.one User
    assert user.email == @email
    assert !is_nil(user.hashed_confirmation_token)

    mail =  Mailman.TestServer.deliveries |> List.last |> Mailman.Email.parse!

    assert mail.from == "test@example.com"
    assert mail.to == ["User <#{@email}>"]
    assert mail.subject == "Hello " <> @email
    assert mail.text == "Hello user@example.com!\n\nWelcome to Test App\n\n"
  end

  test "confirmable :false sign up" do
    Config.persist([sentinel: [confirmable: false]])
    Config.persist([sentinel: [invitable: false]])

    conn = call(TestRouter, :post, "/api/users", %{user: %{password: @password, email: @email}}, @headers)
    assert conn.status == 201
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token

    user = TestRepo.one User
    assert user.email == @email
    assert !is_nil(user.hashed_confirmation_token)

    assert length(Mailman.TestServer.deliveries) == 0
  end

  test "invitable sign up" do
    Config.persist([sentinel: [invitable: true]])
    Config.persist([sentinel: [confirmable: false]])

    conn = call(TestRouter, :post, "/api/users", %{user: %{email: @email}}, @headers)
    assert conn.status == 201
    assert Poison.decode!(conn.resp_body) == "ok"

    mail =  Mailman.TestServer.deliveries |> List.last |> Mailman.Email.parse!

    assert mail.from == "test@example.com"
    assert mail.to == ["User <#{@email}>"]
    assert mail.subject == "You've been invited to Test App " <> @email
    assert mail.text == "Hello user@example.com!\n\n\You've been invited to Test App\n\n"
  end

  test "invitable and confirmable sign up" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: true]])

    conn = call(TestRouter, :post, "/api/users", %{user: %{email: @email}}, @headers)
    assert conn.status == 201
    assert Poison.decode!(conn.resp_body) == "ok"

    mail =  Mailman.TestServer.deliveries |> List.last |> Mailman.Email.parse!

    assert mail.from == "test@example.com"
    assert mail.to == ["User <#{@email}>"]
    assert mail.subject == "You've been invited to Test App " <> @email
    assert mail.text == "Hello user@example.com!\n\n\You've been invited to Test App\n\n"
  end

  test "invitable setup password" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: true]])

    {confirmation_token, changeset} = Registrator.changeset(%{email: @email})
                                      |> Confirmator.confirmation_needed_changeset
    user = repo.insert!(changeset)

    {password_reset_token, changeset} = PasswordResetter.create_changeset(user)
    user = repo.update!(changeset)

    conn = call(TestRouter, :post, "/api/users/#{user.id}/invited", %{confirmation_token: confirmation_token, password_reset_token: password_reset_token, password: @password}, @headers)
    assert conn.status == 201
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token
    updated_user = repo.get! UserHelper.model, user.id

    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.hashed_password_reset_token == nil
    assert updated_user.unconfirmed_email == nil
  end

  test "sign up with missing password without the invitable module enabled" do
    Config.persist([sentinel: [invitable: false]])
    conn = call(TestRouter, :post, "/api/users", %{user: %{email: @email}}, @headers)
    assert conn.status == 422

    errors = Poison.decode!(conn.resp_body)
              |> Dict.fetch!("errors")

    assert errors["password"] == "can't be blank"
  end

  test "sign up with missing email" do
    conn = call(TestRouter, :post, "/api/users", %{"user" => %{"password" => @password}}, @headers)
    assert conn.status == 422

    errors = Poison.decode!(conn.resp_body)
              |> Dict.fetch!("errors")

    assert errors["email"] == "can't be blank"
  end

  test "sign up with custom validations" do
    Config.persist([sentinel: [confirmable: :optional]])
    Config.persist([sentinel: [invitable: false]])

    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Ecto.Changeset.add_error(changeset, :password, "too_short")
    end)
    conn = call(TestRouter, :post, "/api/users", %{user: %{email: @email, password: @password}}, @headers)
    assert conn.status == 422

    errors = Poison.decode!(conn.resp_body)
              |> Dict.fetch!("errors")

    assert errors["password"] == "too_short"
  end
end
