defmodule UserControllerTest do
  use Sentinel.Case
  use Plug.Test

  import RouterHelper
  alias Sentinel.TestRouter
  alias Sentinel.TestRepo
  alias Sentinel.User
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

    conn = call(TestRouter, :post, "/api/users", %{user: %{password: @password, email: @email}}, @headers)
    assert conn.status == 200
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

    conn = call(TestRouter, :post, "/api/users", %{user: %{password: @password, email: @email}}, @headers)
    assert conn.status == 200
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
    Config.persist([sentinel: [confirmable: :false]])

    conn = call(TestRouter, :post, "/api/users", %{user: %{password: @password, email: @email}}, @headers)
    assert conn.status == 200
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token

    user = TestRepo.one User
    assert user.email == @email
    assert !is_nil(user.hashed_confirmation_token)

    assert length(Mailman.TestServer.deliveries) == 0
  end

  test "sign up with missing email" do
    conn = call(TestRouter, :post, "/api/users", %{"user" => %{"password" => @password}}, @headers)
    assert conn.status == 422

    errors = Poison.decode!(conn.resp_body)
              |> Dict.fetch!("errors")

    assert errors["email"] == "can't be blank"
  end

  test "sign up with missing password" do
    conn = call(TestRouter, :post, "/api/users", %{user: %{email: @email}}, @headers)
    assert conn.status == 422

    errors = Poison.decode!(conn.resp_body)
              |> Dict.fetch!("errors")

    assert errors["password"] == "can't be blank"
  end

  test "sign up with custom validations" do
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
