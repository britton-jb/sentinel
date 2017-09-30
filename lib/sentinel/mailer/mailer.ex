defmodule Sentinel.Mailer do
  alias Sentinel.{Config, Mailer}

  use Bamboo.Mailer, otp_app: Sentinel.Config.otp_app
  use Bamboo.Phoenix, view: Config.views.email

  @moduledoc """
  Provides mailer base imported into mailer modules

  ## Examples
      defmodule Sentinel.Mailer.NewEmailAddress do
        import Sentinel.Mailer

        def send(user, confirmation_token) do
          base_email(user)
          |> to(user.unconfirmed_email)
          |> subject("Please confirm your email address")
          |> assign(:user, user)
          |> assign(:confirmation_token, confirmation_token)
          |> render(:new_email_address)
        end
      end
  """

  @doc """
    Retrives the default application from tuple
  """
  def from do
    {Mailer.app_name || Mailer.send_address, Mailer.send_address}
  end

  @doc """
    Retrives the default application email sender
  """
  def send_address do
    Sentinel.Config.send_address
  end

  @doc """
    Retrives the default application reply to email
  """
  def reply_to do
    Sentinel.Config.reply_to
  end

  @doc """
    Retrives the app name used in emails sent
  """
  def app_name do
    Sentinel.Config.app_name
  end

  @doc """
    Provides base email that can be piped using functions described in the
    Bamboo module
  """
  def base_email(user) do
    new_email()
    |> put_layout({Sentinel.EmailLayoutView, :email})
    |> to(user)
    |> from(Mailer.from)
    |> put_header("Reply-To", reply_to())
  end

  @doc """
  Thin wrapper around the Sentinel.Mailer.NewEmailAddress module
  """
  def send_new_email_address_email(user, confirmation_token) do
    user
    |> Sentinel.Mailer.NewEmailAddress.build(confirmation_token)
    |> Mailer.managed_deliver
  end

  @doc """
  Thin wrapper around the Sentinel.Mailer.PasswordReset module
  """
  def send_password_reset_email(user, password_reset_token) do
    user
    |> Sentinel.Mailer.PasswordReset.build(password_reset_token)
    |> Mailer.managed_deliver
  end

  @doc """
  Thin wrapper around the Sentinel.Mailer.Welcome module
  """
  def send_welcome_email(user, confirmation_token) do
    user
    |> Sentinel.Mailer.Welcome.build(confirmation_token)
    |> Mailer.managed_deliver
  end

  @doc """
  Thin wrapper around the Sentinel.Mailer.Invite module
  """
  def send_invite_email(user, %{confirmation_token: confirmation_token, password_reset_token: password_reset_token}) do
    user
    |> Sentinel.Mailer.Invite.build(%{confirmation_token: confirmation_token, password_reset_token: password_reset_token})
    |> Mailer.managed_deliver
  end

  @doc """
  Thin wrapper around the Sentinel.Mailer.Unlock module
  """
  def send_locked_account_email(user, unlock_token) do
    user
    |> Sentinel.Mailer.Unlock.build(unlock_token)
    |> Mailer.managed_deliver
  end

  @doc """
    Method used to send and manage delivery of emails, which references config
    ensuring user wants emails to go out in a given environment
  """
  def managed_deliver(email) do
    if send_emails?() do
      Mailer.deliver_later(email)
    end
  end

  defp send_emails? do
    Sentinel.Config.send_emails?
  end
end
