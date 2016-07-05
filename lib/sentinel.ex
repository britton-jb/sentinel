defmodule Sentinel do
  defmacro mount_html do
    quote do
      post    "/users",                 Sentinel.Controllers.Html.User, :create
      post    "/users/:id/invited",     Sentinel.Controllers.Html.User, :invited
      if Application.get_env(:sentinel, :confirmable) != :false do
        post    "/users/:id/confirm",     Sentinel.Controllers.Html.User, :confirm
      end
      post    "/sessions",              Sentinel.Controllers.Html.Session, :create
      delete  "/sessions",              Sentinel.Controllers.Html.Session, :delete
      post    "/password_resets",       Sentinel.Controllers.Html.Password, :create
      post    "/password_resets/reset", Sentinel.Controllers.Html.Password, :reset
      get     "/account",               Sentinel.Controllers.Html.Account, :edit
      put     "/account",               Sentinel.Controllers.Html.Account, :update
    end
  end

  defmacro mount_api do
    quote do
      post    "/users",                 Sentinel.Controllers.Json.User, :create
      post    "/users/:id/invited",     Sentinel.Controllers.Json.User, :invited
      if Application.get_env(:sentinel, :confirmable) != :false do
        post    "/users/:id/confirm",     Sentinel.Controllers.Json.User, :confirm
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
