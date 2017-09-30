defmodule Sentinel.Lockable do
  @moduledoc """
  Implements lockable functionality
  """

  alias Sentinel.{Config, Mailer}

  def send_unlock_email(email) do
    with user      when not is_nil(user)      <- Config.repo.get_by(Config.user_model, email: email),
         auth      when not is_nil(auth)      <- Config.repo.get_by(Sentinel.Ueberauth, provider: "identity", user_id: user.id),
         locked_at when not is_nil(locked_at) <- auth.locked_at do
      Mailer.send_locked_account_email(user, auth.unlock_token)
    else
    _ -> nil
    end
  end
end
