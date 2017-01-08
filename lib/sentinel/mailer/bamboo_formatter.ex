defimpl Bamboo.Formatter, for: Module.concat([Sentinel.UserHelper.model]) do
  def format_email_address(user, %{type: :to}) do
    {user.email, user.email}
  end
end
