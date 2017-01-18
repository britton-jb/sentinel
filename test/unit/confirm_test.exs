defmodule ConfirmTest do
  use Sentinel.UnitCase
  use Bamboo.Test, shared: true

  import Mock

  alias Sentinel.Confirm

  test "send_confirmation_instructions with email, without user existing, should not send email" do
    user = Factory.build(:user)
    mocked_mail = Sentinel.Mailer.Welcome.build(user, "mocked_token")

    with_mock Sentinel.Mailer, [:passthrough], [send_welcome_email: fn(_, _) -> mocked_mail end] do
      Confirm.send_confirmation_instructions(%{"email" => user.email})
      refute_delivered_email mocked_mail
    end
  end

  test "send_confirmation_instructions with email, user exists, with identity ueberauth, should send email" do
    ueberauth = Factory.insert(:ueberauth)
    mocked_mail = Sentinel.Mailer.Welcome.build(ueberauth.user, "mocked_token")

    with_mock Sentinel.Mailer, [:passthrough], [send_welcome_email: fn(_, _) -> mocked_mail end] do
      Confirm.send_confirmation_instructions(%{"email" => ueberauth.user.email})
      assert_delivered_email mocked_mail
    end
  end
end
