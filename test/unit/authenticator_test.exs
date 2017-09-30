defmodule AuthenticatorTest do
  use Sentinel.UnitCase

  alias Sentinel.Authenticator
  alias Sentinel.Ueberauth
  alias Mix.Config

  test "authenticate without db based ueberauth struct" do
    assert {:error, [base: {"Unknown email or password", []}]} = Authenticator.authenticate(nil, "password")
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
    assert {:error, [base: {"Account not confirmed yet. Please follow the instructions we sent you by email.", []}]} = Authenticator.authenticate(
      %Ueberauth{
        hashed_password: Sentinel.Config.crypto_provider.hashpwsalt("password"),
        user: %{confirmed_at: nil}
      },
      "password"
    )
  end

  test "fail to authenticate, lockable enabled" do
    ueberauth = Factory.insert(:ueberauth)

    Config.persist([sentinel: [lockable: true]])

    assert {:error, [base: {"Unknown email or password", []}]} = Authenticator.authenticate(
      ueberauth,
      "wrong_password"
    )

    Config.persist([sentinel: [lockable: false]])
  end

  test "fail to authenticate, lockable enabled, 3 previous failed attempts" do
    ueberauth = Factory.insert(:ueberauth, failed_attempts: 3)

    Config.persist([sentinel: [lockable: true]])

    assert {:error, [lockable: {"You have one more attempt to authenticate correctly before this account is locked.", []}]} = Authenticator.authenticate(
      ueberauth,
      "wrong_password"
    )

    Config.persist([sentinel: [lockable: false]])
  end

  test "fail to authenticate, lockable enabled, 4 previous failed attempts" do
    ueberauth = Factory.insert(:ueberauth, failed_attempts: 4)

    Config.persist([sentinel: [lockable: true]])

    assert {:error, [lockable: {"Your account has been locked. We've sent you email instructions regarding how to unlock it.", []}]} = Authenticator.authenticate(
      ueberauth,
      "wrong_password"
    )

    Config.persist([sentinel: [lockable: false]])
  end

  test "fail to authenticate, lockable enabled, account locked" do
    ueberauth = Factory.insert(:ueberauth, failed_attempts: 5, locked_at: DateTime.utc_now())

    Config.persist([sentinel: [lockable: true]])

    assert {:error, [lockable: {"This account is currently locked. Please follow the instructions in your email to unlock it.", []}]} = Authenticator.authenticate(
      ueberauth,
      "wrong_password"
    )

    Config.persist([sentinel: [lockable: false]])
  end
end
