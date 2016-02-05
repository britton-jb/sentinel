defmodule AuthenticatorTest do
  use Sentinel.Case
  alias Sentinel.TestRepo
  alias Sentinel.Authenticator
  alias Sentinel.User
  alias Mix.Config

  @email "user@example.com"
  @password "secret"

  test "authenticate a confirmed user" do
    user = Forge.saved_confirmed_user
    {:ok, _} = Authenticator.authenticate_by_email(user.email, "secret")
  end

  test "authenticate an unconfirmed user - confirmable default/optional" do
    Config.persist([sentinel: [confirmable: :optional]])

    user = Forge.saved_user
    assert Authenticator.authenticate_by_email(user.email, "secret") == {:ok, user}
  end

  test "authenticate an unconfirmed user - confirmable false" do
    Config.persist([sentinel: [confirmable: :false]])

    user = Forge.saved_user
    assert Authenticator.authenticate_by_email(user.email, "secret") == {:ok, user}
  end

  test "authenticate an unconfirmed user - confirmable required" do
    Config.persist([sentinel: [confirmable: :required]])

    user = Forge.saved_user
    assert Authenticator.authenticate_by_email(user.email, "secret") == {:error, %{base: "Account not confirmed yet. Please follow the instructions we sent you by email."}}
  end

  test "authenticate an unknown user" do
    assert Authenticator.authenticate_by_email("user@example.com", "secret") == {:error, %{base: "Unknown email or password"}}
  end
end
