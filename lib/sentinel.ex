defmodule Sentinel do
  @moduledoc """
  Module responsible for the macros that mount the Sentinel routes
  """

  defmacro mount_ueberauth do
    run_compile_time_checks

    quote do
      require Ueberauth

      scope "/auth", Sentinel.Controllers do
        get "/sessions/new", AuthController, :new
        post "/sessions", AuthController, :create
        delete "/sessions", AuthController, :delete

        get "/:provider", AuthController, :request
        get "/:provider/callback", AuthController, :callback
        post "/:provider/callback", AuthController, :callback
      end
    end
  end

  defp run_compile_time_checks do
    if is_nil(Sentinel.Config.send_address) do
      raise "Must configure :sentinel :send_address"
    end
    if is_nil(Sentinel.Config.router) && is_nil(Sentinel.Config.endpoint) do
      raise "Must configure :sentinel :router and :endpoint"
    end
    if is_nil(Sentinel.Config.router) do
      raise "Must configure :sentinel :router"
    end
    if is_nil(Sentinel.Config.endpoint) do
      raise "Must configure :sentinel :endpoint"
    end
  end

  @doc """
  Mount's Sentinel HTML routes inside your application
  """
  defmacro mount_html do
    quote do
      require Ueberauth

      scope "/", Sentinel.Controllers do
        get "/users/new", Html.UserController, :new
        post "/users", Html.UserController, :create
        if Sentinel.invitable? do
          get "/users/:id/invited", Html.UserController, :invitation_registration
          post "/users/:id/invited", Html.UserController, :invited
        end
        if Sentinel.confirmable? do
          get "/confirmation_instructions", Html.UserController, :confirmation_instructions
          post "/confirmation", Html.UserController, :confirm
        end

        get "/password/new", Html.PasswordController, :new
        post "/password/new", Html.PasswordController, :create
        get "/password/edit", Html.PasswordController, :edit
        put "/password", Html.PasswordController, :update

        get "/account", Html.AccountController, :edit
        put "/account", Html.AccountController, :update
        put "/account/password", Html.PasswordController, :authenticated_update
      end
    end
  end

  @doc """
  Mount's Sentinel JSON API routes inside your application
  """
  defmacro mount_api do
    if Sentinel.invitable? && !Sentinel.invitable_configured? do
      raise "Must configure :sentinel :invitation_registration_url when using sentinel invitable API"
    end

    quote do
      require Ueberauth

      scope "/", Sentinel.Controllers do
        if Sentinel.invitable? do
          post "/users/:id/invited", Json.UserController, :invited
        end
        if Sentinel.confirmable? do
          post "/confirmation", Json.UserController, :confirm
        end

        get "/password/new", Json.PasswordController, :new
        post "/password", Json.PasswordController, :create
        put "/password", Json.PasswordController, :update

        get "/account", Json.AccountController, :show
        put "/account", Json.AccountController, :update
        put "/account/password", Json.PasswordController, :authenticated_update
      end
    end
  end

  def invitable? do
    Sentinel.Config.invitable
  end

  def invitable_configured? do
    Sentinel.Config.invitable_configured?
  end

  def confirmable? do
    Sentinel.Config.confirmable
  end
end
