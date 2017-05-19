defmodule AuthenticatorTest do
  use Sentinel.UnitCase

  alias Sentinel.Authenticator
  alias Sentinel.Ueberauth
  alias Mix.Config

  test "authenticate without db based ueberauth struct" do
    assert {:error, %{base: "Unknown email or password"}} = Authenticator.authenticate(nil, "password")
  end

  test "authenticate with db based ueberauth struct" do
    assert {:ok, _user} = Authenticator.authenticate(%Ueberauth{hashed_password: Sentinel.Config.crypto_provider.hashpwsalt("password"), user: %{}}, "password")
  end

  test "authenticate with db based ueberauth struct, confirmation required, user confirmed" do
    Config.persist([sentinel: [confirmable: :required]])
    assert {:ok, _user} = Authenticator.authenticate(%Ueberauth{hashed_password: Sentinel.Config.crypto_provider.hashpwsalt("password"), user: %{}}, "password")
  end

  test "authenticate with db based ueberauth struct, confirmation required, user not confirmed" do
    Config.persist([sentinel: [confirmable: :required]])
    assert {:error, %{base: "Account not confirmed yet. Please follow the instructions we sent you by email."}} = Authenticator.authenticate(
      %Ueberauth{
        hashed_password: Sentinel.Config.crypto_provider.hashpwsalt("password"),
        user: %{confirmed_at: nil}
      },
      "password"
    )
  end

  test "fail to authenticate, lockable enabled" do
    Config.persist([sentinel: [lockable: true]])

    assert {:error, %{base: "Unknown email or password"}} = Authenticator.authenticate(
      %Ueberauth{
        hashed_password: Sentinel.Config.crypto_provider.hashpwsalt("password"),
        user: %{confirmed_at: nil}
      },
      "wrong_password"
    )

    Config.persist([sentinel: [lockable: false]])
  end
end