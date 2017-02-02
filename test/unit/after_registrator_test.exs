defmodule AfterRegistratorTest do
  use Sentinel.UnitCase
  use Bamboo.Test, shared: true

  alias Mix.Config
  alias Sentinel.AfterRegistrator
  alias Sentinel.Mailer.Invite
  alias Sentinel.Mailer.Welcome

  import Mock

  setup do
    on_exit fn ->
      Config.persist([sentinel: [confirmable: :optional]])
      Config.persist([sentinel: [invitable: true]])
    end

    auth = Factory.insert(:ueberauth)
    invited_auth = Factory.insert(:ueberauth, hashed_password: nil)

    mocked_token = SecureRandom.urlsafe_base64()

    welcome_email = Welcome.build(auth.user, mocked_token)
    invite_email = Invite.build(
      invited_auth.user,
      %{
        confirmation_token: mocked_token,
        password_reset_token: mocked_token
      })

    {:ok,
      %{
        auth: auth,
        invited_auth: invited_auth,
        welcome_email: welcome_email,
        invite_email: invite_email,
        mocked_token: mocked_token
      }
    }
  end

  test "not confirmable or invitable", %{auth: auth, mocked_token: mocked_token, welcome_email: welcome_email} do
    Config.persist([sentinel: [confirmable: false]])
    Config.persist([sentinel: [invitable: false]])

    AfterRegistrator.confirmable_and_invitable(auth.user, mocked_token)
    refute_delivered_email welcome_email
  end

  test "invitable, no password", %{invited_auth: invited, mocked_token: mocked_token, invite_email: invite_email} do
    Config.persist([sentinel: [invitable: true]])

    hashed_password_reset_token = Sentinel.Config.crypto_provider.hashpwsalt(mocked_token)
    mocked_changeset =
      invited
      |> Ecto.Changeset.cast(%{}, [])
      |> Ecto.Changeset.put_change(:hashed_password_reset_token, hashed_password_reset_token)

    with_mock Sentinel.Changeset.PasswordResetter, [:passthrough], [create_changeset: fn(_) -> {mocked_token, mocked_changeset} end] do
      AfterRegistrator.confirmable_and_invitable(invited.user, mocked_token)

      refute_delivered_email Welcome.build(invited.user, mocked_token)
      assert_delivered_email invite_email
    end
  end

  test "invitable, with password", %{auth: auth, mocked_token: mocked_token, welcome_email: welcome_email, invite_email: invite_email} do
    Config.persist([sentinel: [invitable: true]])

    AfterRegistrator.confirmable_and_invitable(auth.user, mocked_token)
    refute_delivered_email Invite.build(auth.user, %{confirmation_token: mocked_token, password_reset_token: mocked_token})
    refute_delivered_email invite_email
    assert_delivered_email welcome_email
  end

  test "confirmable", %{auth: auth, mocked_token: mocked_token, welcome_email: welcome_email} do
    Config.persist([sentinel: [confirmable: true]])
    Config.persist([sentinel: [invitable: false]])

    AfterRegistrator.confirmable_and_invitable(auth.user, mocked_token)
    assert_delivered_email welcome_email
  end
end
