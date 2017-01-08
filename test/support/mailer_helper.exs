defmodule Support.MailerHelper do
  def from_email do
    {
      Application.get_env(:sentinel, :app_name),
      Application.get_env(:sentinel, :send_address)
    }
  end
end
