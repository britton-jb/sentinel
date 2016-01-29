defmodule Blacksmith.Config do
  alias Sentinel.Util
  alias Sentinel.UserHelper

  def save(map) do
    Util.repo.insert!(map)
  end

  def save_all(list) do
    Enum.map(list, &Util.repo.insert!/1)
  end
end

defmodule Forge do
  use Blacksmith

  @save_one_function &Blacksmith.Config.save/1
  @save_all_function &Blacksmith.Config.save_all/1

  register(:user, %Sentinel.User{
    email: Sequence.next(:email, &"user#{&1}@example.com"),
    username: Sequence.next(:username, &"user#{&1}@example.com"),
    hashed_password: Sentinel.Util.crypto_provider.hashpwsalt("secret"),
    role: "user",
    confirmed_at: nil
  })

  register(:confirmed_user,
    [prototype: :user],
    confirmed_at: Ecto.DateTime.utc
  )
end
