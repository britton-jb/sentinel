defmodule Sentinel do
  @moduledoc """
  Module responsible for the macros that mount the Sentinel routes
  """

  @doc """
  Mounts Sentinel HTML and JSON auth routes inside your application
  """
  defmacro mount_ueberauth do
    run_ueberauth_compile_time_checks()

    quote do
      require Ueberauth

      scope "/", Sentinel.Controllers do
        get "/login", AuthController, :new
        post "/login", AuthController, :create
        get "/logout", AuthController, :delete
      end

      scope "/auth", Sentinel.Controllers do
        get "/session/new", AuthController, :new
        post "/session", AuthController, :create
        delete "/session", AuthController, :delete

        get "/:provider", AuthController, :request
        get "/:provider/callback", AuthController, :callback
        post "/:provider/callback", AuthController, :callback
      end
    end
  end

  defp run_ueberauth_compile_time_checks do
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
  Mounts Sentinel HTML routes inside your application
  """
  defmacro mount_html do
    quote do
      require Ueberauth

      scope "/", Sentinel.Controllers.Html do

        if Sentinel.registerable? do
          get "/user/new", UserController, :new
        end

        if Sentinel.invitable? do
          get "/user/:id/invited", UserController, :invitation_registration
          put "/user/:id/invited", UserController, :invited
        end
        if Sentinel.confirmable? do
          get "/user/confirmation_instructions", UserController, :confirmation_instructions
          post "/user/confirmation_instructions", UserController, :resend_confirmation_instructions
          get "/user/confirmation", UserController, :confirm
        end
        if Sentinel.lockable? do
          get "/unlock", UnlockController, :new
          post "/unlock", UnlockController, :create
          put "/unlock", UnlockController, :update
        end

        get "/password/new", PasswordController, :new
        post "/password", PasswordController, :create
        get "/password/edit", PasswordController, :edit
        put "/password", PasswordController, :update

        get "/account", AccountController, :edit
        put "/account", AccountController, :update
        put "/account/password", PasswordController, :authenticated_update
      end
    end
  end

  @doc """
  Mounts Sentinel JSON API routes inside your application
  """
  defmacro mount_api do
    run_api_compile_time_checks()

    quote do
      require Ueberauth

      scope "/", Sentinel.Controllers.Json do
        if Sentinel.invitable? do
          get "/user/:id/invited", UserController, :invitation_registration
          put "/user/:id/invited", UserController, :invited
        end
        if Sentinel.confirmable? do
          post "/user/confirmation_instructions", UserController, :resend_confirmation_instructions
          get "/user/confirmation", UserController, :confirm
        end
        if Sentinel.lockable? do
          post "/unlock", UnlockController, :create
          put "/unlock", UnlockController, :update
        end

        get "/password/new", PasswordController, :new
        get "/password/edit", PasswordController, :edit
        put "/password", PasswordController, :update

        get "/account", AccountController, :show
        put "/account", AccountController, :update
        put "/account/password", PasswordController, :authenticated_update
      end
    end
  end

  defp run_api_compile_time_checks do
    unless Sentinel.Config.password_reset_url do
      raise "Must configure :sentinel :password_reset_url when using sentinel API"
    end

    if Sentinel.invitable? && !Sentinel.invitable_configured? do
      raise "Must configure :sentinel :invitation_registration_url when using sentinel invitable API"
    end

    if Sentinel.confirmable? && !Sentinel.confirmable_configured? do
      raise "Must configure :sentinel :confirmable_redirect_url when using sentinel confirmable API"
    end
  end

  def invite(attrs) do
    with auth                                                         <- coerce_to_auth(attrs),
         {:ok, %{user: user, confirmation_token: confirmation_token}} <- Sentinel.Ueberauthenticator.ueberauthenticate(auth),
         {:ok, user}                                                  <- Sentinel.AfterRegistrator.confirmable_and_invitable(user, confirmation_token),
         {:ok, user}                                                  <- Sentinel.RegistratorHelper.callback(user),
         ueberauth when not is_nil(ueberauth)                         <- Sentinel.Config.repo.get_by(Sentinel.Ueberauth, user_id: user.id),
         true                                                         <- is_nil(ueberauth.hashed_password) do
    else
      _ -> {:error, "Unable to invite user"}
    end
  end

  defp coerce_to_auth(attrs) do
    %Ueberauth.Auth{
      provider: :identity,
      credentials: %Ueberauth.Auth.Credentials{other: %{password: nil}},
      extra: %{
        raw_info: attrs
      }
    }
  end

  def invitable? do
    Sentinel.Config.invitable
  end

  def invitable_configured? do
    Sentinel.Config.invitable_configured?
  end

  def confirmable? do
    Sentinel.Config.confirmable != false # defaults to :optional
  end

  def confirmable_configured? do
    Sentinel.Config.confirmable_redirect_url
  end

  def registerable? do
    Sentinel.Config.registerable?
  end

  def lockable? do
    Sentinel.Config.lockable?
  end
end
