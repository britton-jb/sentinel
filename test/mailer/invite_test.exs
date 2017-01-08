defmodule Mailer.InviteTest do
  use Sentinel.UnitCase

  @from_email Support.MailerHelper.from_email
  defp to_email do
    "to_email@example.com"
  end

  setup do
    mocked_confirmation_token = SecureRandom.urlsafe_base64()
    mocked_password_reset_token = SecureRandom.urlsafe_base64()
    user = Factory.insert(:user, email: to_email)
    mocked_mail = Sentinel.Mailer.Invite.build(
      user,
      {mocked_confirmation_token, mocked_password_reset_token}
    ) |> Sentinel.Mailer.managed_deliver

    {:ok, %{mocked_mail: mocked_mail}}
  end

  test "renders correct from", %{mocked_mail: mocked_mail} do
    assert mocked_mail.from == @from_email
  end

  test "renders correct to", %{mocked_mail: mocked_mail} do
    assert mocked_mail.to == [{to_email, to_email}]
  end

  test "renders correct subject", %{mocked_mail: mocked_mail} do
    assert mocked_mail.subject == "You've been invited to #{app_name} #{to_email}"
  end

  test "renders correct html body", %{mocked_mail: mocked_mail} do
    refute mocked_mail.html_body == ""
  end

  test "renders correct text body", %{mocked_mail: mocked_mail} do
    refute mocked_mail.html_body == ""
  end

  defp app_name do
    Application.get_env(:sentinel, :app_name)
  end
end
