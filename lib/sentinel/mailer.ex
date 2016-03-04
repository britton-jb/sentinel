defmodule Sentinel.Mailer do
  alias Mailman.Email

  def deliver(email, config) do
    if email do
      Mailman.deliver(email, config)
    end
  end

  def email_sender do
    Application.get_env(:sentinel, :email_sender)
  end

  def reply_to do
    Application.get_env(:sentinel, :reply_to) || email_sender
  end

  def send_new_email_address_email(user, confirmation_token, language \\ :en) do
    language_string = Atom.to_string(language)

    email =  %Email{
      from: email_sender,
      reply_to: reply_to,
      to: [user.unconfirmed_email],
      data: [user: user, confirmation_token: confirmation_token],
      subject: "Please confirm your email address",
      html: "/#{language_string}/new_email_address.html.eex",
      text: "/#{language_string}/new_email_address.txt.eex",
    }

    deliver(email, config)
  end

  def send_password_reset_email(user, password_reset_token, language \\ :en) do
    language_string = Atom.to_string(language)

    email =  %Email{
      from: email_sender,
      reply_to: reply_to,
      to: [user.email],
      data: [user: user, password_reset_token: password_reset_token],
      subject: "Reset Your Password",
      html: "/#{language_string}/password_reset.html.eex",
      text: "/#{language_string}/password_reset.txt.eex",
    }

    deliver(email, config)
  end

  def send_welcome_email(user, confirmation_token, language \\ :en) do
    language_string = Atom.to_string(language)

    email =  %Email{
      from: email_sender,
      reply_to: reply_to,
      to: [user.email],
      data: [user: user, confirmation_token: confirmation_token],
      subject: "Hello #{user.email}",
      html: "/#{language_string}/welcome.html.eex",
      text: "/#{language_string}/welcome.txt.eex",
    }

    deliver(email, config)
  end

  def env_config do
    case Mix.env do
      :test ->
        %Mailman.TestConfig{}
      _ ->
        %Mailman.LocalSmtpConfig{ port: Application.get_env(:mailman, :port)}
    end
  end

  def config do
    %Mailman.Context{
      config: env_config,
      composer: %Mailman.EexComposeConfig{
        html_file: true,
        text_file: true,
        html_file_path: Application.get_env(:mailman, :html_email_templates) || Path.expand("templates/", __DIR__),
        text_file_path: Application.get_env(:mailman, :text_email_templates) || Path.expand("templates/", __DIR__),
      }
    }
  end
end
