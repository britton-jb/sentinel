defmodule Sentinel do
  defmacro mount_html do
    quote do
      get     "/users",                 Sentinel.Controllers.Html.User, :new
      post    "/users",                 Sentinel.Controllers.Html.User, :create
      post    "/users/:id/invited",     Sentinel.Controllers.Html.User, :invited
      if Application.get_env(:sentinel, :confirmable) != :false do
        get     "/confirmation_instructions", Sentinel.Controllers.Html.User, :confirmation_instructions
        post    "/users/confirm",         Sentinel.Controllers.Html.User, :confirm
      end
      get     "/sessions",              Sentinel.Controllers.Html.Sessions, :new
      post    "/sessions",              Sentinel.Controllers.Html.Sessions, :create
      delete  "/sessions",              Sentinel.Controllers.Html.Sessions, :delete
      get     "/password_resets",       Sentinel.Controllers.Html.PasswordResets, :new
      post    "/password_resets",       Sentinel.Controllers.Html.PasswordResets, :create
      post    "/password_resets/reset", Sentinel.Controllers.Html.PasswordResets, :reset
      get     "/account",               Sentinel.Controllers.Html.Account, :edit
      put     "/account",               Sentinel.Controllers.Html.Account, :update
    end
  end

  defmacro mount_api do
    quote do
      post    "/users",                 Sentinel.Controllers.Json.User, :create
      post    "/users/:id/invited",     Sentinel.Controllers.Json.User, :invited
      if Application.get_env(:sentinel, :confirmable) != :false do
        post    "/users/confirm",     Sentinel.Controllers.Json.User, :confirm
      end
      post    "/sessions",              Sentinel.Controllers.Json.Session, :create
      delete  "/sessions",              Sentinel.Controllers.Json.Session, :delete
      post    "/password_resets",       Sentinel.Controllers.Json.Password, :create
      post    "/password_resets/reset", Sentinel.Controllers.Json.Password, :reset
      get     "/account",               Sentinel.Controllers.Json.Account, :show
      put     "/account",               Sentinel.Controllers.Json.Account, :update
    end
  end
end
