defmodule Sentinel do
  @moduledoc """
  Module responsible for the macros that mount the Sentinel routes
  """

  require Ueberauth

  alias Sentinel.Config
  alias Sentinel.Controllers.Html
  alias Sentinel.Controllers.Json

  @doc """
  Mount's Sentinel HTML routes inside your application
  """
  defmacro mount_html do
    quote do
      require Ueberauth

      scope "/auth" do #FIXME really scope all of this in auth?
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

        get "/sessions/new", Html.AuthController, :new
        post "/sessions", Html.AuthController, :create
        delete "/sessions", Html.AuthController, :delete

        get "/password/new", Html.PasswordController, :new
        post "/password/new", Html.PasswordController, :create
        put "/password", Html.PasswordController, :update

        get "/account", Html.AccountController, :edit
        put "/account", Html.AccountController, :update

        #FIXME setup
        get "/:provider", Html.AuthController, :request
        get "/:provider/callback", Html.AuthController, :callback
        post "/:provider/callback", Html.AuthController, :callback
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

      scope "/auth" do #FIXME really scope all of this in auth?
        if Sentinel.invitable? do
          post "/users/:id/invited", Json.UserController, :invited
        end
        if Sentinel.confirmable? do
          post "/confirmation", Json.UserController, :confirm
        end

        get "/password/new", Json.PasswordController, :new
        put "/password", Json.PasswordController, :update

        get "/account", Json.AccountController, :show
        put "/account", Json.AccountController, :update
        put "/account/password", Json.PasswordController, :authenticated_update

        post "/sessions", Json.AuthController, :create
        delete "/sessions", Json.AuthController, :delete

        get "/:provider", Json.AuthController, :request
        get "/:provider/callback", Json.AuthController, :callback
        post "/:provider/callback", Json.AuthController, :callback
        delete "/", Json.AuthController, :delete
      end
    end
  end

  def invitable? do
    Config.invitable
  end

  def invitable_configured? do
    Config.invitable_configured?
  end

  def confirmable? do
    Config.confirmable
  end
end
