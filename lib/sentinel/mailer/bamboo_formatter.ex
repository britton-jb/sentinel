defimpl Bamboo.Formatter, for: Module.concat([Sentinel.Config.user_model]) do
  def format_email_address(user, %{type: :to}) do
    {user.email, user.email}
  end
end
