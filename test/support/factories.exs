defmodule Sentinel.Factory do
  use ExMachina.Ecto, repo: Sentinel.TestRepo

  def user_factory do
    %Sentinel.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      role: "user",
      confirmed_at: nil,
    }
  end

  def ueberauth_factory do
    user = insert(:user)

    %Sentinel.Ueberauth{
      hashed_password: Sentinel.Config.crypto_provider.hashpwsalt("password"),
      provider: "identity",
      user: user,
      uid: "#{user.id}"
    } |> Map.put(:plain_text_password, "password")
  end
end
