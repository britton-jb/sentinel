defmodule Sentinel.Mailer do
  use Bamboo.Mailer, otp_app: :sentinel
  use Bamboo.Phoenix, view: Sentinel.EmailView
  import Bamboo.Email

  defp email_sender do
    Application.get_env(:sentinel, :email_sender)
  end

  defp reply_to do
    Application.get_env(:sentinel, :reply_to) || email_sender
  end

  defp send_emails? do
    Application.get_env(:sentinel, :send_emails)
  end

  def app_name do
    Application.get_env(:sentinel, :app_name)
  end

  def base_email(user) do
    new_email
    |> put_layout({Sentinel.EmailLayoutView, :email})
    |> to(user.email)
    |> from(email_sender)
    |> put_header("Reply-To", reply_to)
  end

  def send_new_email_address_email(user, confirmation_token) do
    Sentinel.Mailer.base_email(user)
    |> to(user.unconfirmed_email)
    |> subject("Please confirm your email address")
    |> assign(:user, user)
    |> assign(:confirmation_token, confirmation_token)
    |> render(:new_email_address)
  end

  def send_password_reset_email(user, password_reset_token) do
    Sentinel.Mailer.base_email(user)
    |> assign(:user, user)
    |> assign(:password_reset_token, password_reset_token)
    |> subject("Reset Your Password")
    |> render(:password_reset)
  end

  def send_welcome_email(user, confirmation_token) do
    Sentinel.Mailer.base_email(user)
    |> assign(:user, user)
    |> assign(:confirmation_token, confirmation_token)
    |> subject("Hello #{user.email}")
    |> render(:welcome)
  end

  def send_invite_email(user, {confirmation_token, password_reset_token}) do
    Sentinel.Mailer.base_email(user)
    |> assign(:user, user)
    |> assign(:confirmation_token, confirmation_token)
    |> assign(:password_reset_token, password_reset_token)
    |> subject("You've been invited to #{app_name} #{user.email}")
    |> render("invite.html")
  end

  def managed_deliver(email) do
    if send_emails? do
      Sentinel.Mailer.deliver_later(email)
    end
  end
end
