defmodule Mailer.PasswordResetTest do
  use Sentinel.UnitCase

  @from_email Support.MailerHelper.from_email
  @email "to_email@example.com"

  setup_all do
    mocked_password_reset_token = SecureRandom.urlsafe_base64()
    mocked_mail = Sentinel.Mailer.PasswordReset.build(%Sentinel.User{
      email: @email
    }, mocked_password_reset_token) |> Sentinel.Mailer.managed_deliver

    {:ok, %{mocked_mail: mocked_mail}}
  end

  test "renders correct from", %{mocked_mail: mocked_mail} do
    assert mocked_mail.from == @from_email
  end

  test "renders correct to", %{mocked_mail: mocked_mail} do
    assert mocked_mail.to == [{@email, @email}]
  end

  test "renders correct subject", %{mocked_mail: mocked_mail} do
    assert mocked_mail.subject == "Reset Your Password"
  end

  test "renders correct html body", %{mocked_mail: mocked_mail} do
    refute mocked_mail.html_body == ""
  end

  test "renders correct text body", %{mocked_mail: mocked_mail} do
    refute mocked_mail.html_body == ""
  end
end
