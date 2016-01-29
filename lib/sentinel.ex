defmodule Sentinel do
  defmacro mount do
    quote do
      post    "users",                 Sentinel.Controllers.Users, :create
      if Application.get_env(:sentinel, :confirmable) != :false do
        post    "users/:id/confirm",     Sentinel.Controllers.Users, :confirm
      end
      post    "sessions",              Sentinel.Controllers.Sessions, :create
      delete  "sessions",              Sentinel.Controllers.Sessions, :delete
      post    "password_resets",       Sentinel.Controllers.PasswordResets, :create
      post    "password_resets/reset", Sentinel.Controllers.PasswordResets, :reset
      get     "account",               Sentinel.Controllers.Account, :show
      put     "account",               Sentinel.Controllers.Account, :update
    end
  end
end
