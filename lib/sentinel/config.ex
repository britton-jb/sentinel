defmodule Sentinel.Config do
  @moduledoc """
  Wraps application configuration for Sentinel for easy access
  """

  @doc """
  Wrapper for getting the application config of :app_name
  """
  def app_name do
    Application.get_env(:sentinel, :app_name)
  end

  @doc """
  Wrapper for getting the application config of :confirmable
  """
  def confirmable do
    Application.get_env(:sentinel, :confirmable, :optional)
  end

  @doc """
  Wrapper for getting the application config of :crypto_provider
  """
  def crypto_provider do
    Application.get_env(:sentinel, :crypto_provider, Comeonin.Bcrypt)
  end

  @doc """
  Wrapper for getting the application config of :email_css
  """
  def email_css_url do
    Application.get_env(:sentinel, :email_css, "")
  end

  @doc """
  Wrapper for getting the application config of :endpoint
  """
  def endpoint do
    Application.get_env(:sentinel, :endpoint)
  end

  @doc """
  Wrapper for getting the application config of :invitable
  """
  def invitable do
    Application.get_env(:sentinel, :invitable, false)
  end

  @doc """
  Helper method ensuring invitable is properly configured
  """
  def invitable_configured? do
    invitable() && invitation_registration_url()
  end

  @doc """
  Wrapper for getting the application config of :confirmable_redirect_url
  """
  def confirmable_redirect_url do
    Application.get_env(:sentinel, :confirmable_redirect_url)
  end

  @doc """
  Wrapper for getting the application config of :password_reset_url
  """
  def password_reset_url do
    Application.get_env(:sentinel, :password_reset_url)
  end

  @doc """
  Wrapper for getting the application config of :invitation_registration_url
  """
  def invitation_registration_url do
    Application.get_env(:sentinel, :invitation_registration_url)
  end

  @doc """
  Checks if guardian_db is present
  """
  def guardian_db? do
    Code.ensure_loaded?(GuardianDb)
  end

  @doc """
  Wrapper for the application config that may contain a user's custom
  password validation changeset
  """
  def password_validation do
    Application.get_env(
      :sentinel,
      :password_validation,
      {
        Sentinel.PasswordValidator,
        :default_sentinel_password_validation
      }
    )
  end

  @doc """
  Wrapper for getting the application config of :registerable module
  """
  def registerable? do
    Application.get_env(:sentinel, :registerable, true)
  end

  @doc """
  Wrapper for getting the application config of :reply_to, defaults to the send_address
  """
  def reply_to do
    Application.get_env(:sentinel, :reply_to, send_address())
  end

  @doc """
  Wrapper for getting the application config of :repo
  """
  def repo do
    Application.get_env(:sentinel, :repo)
  end

  @doc """
  Wrapper for getting the application config of :router
  """
  def router do
    Application.get_env(:sentinel, :router)
  end

  @doc """
  Wrapper for getting the application config of :router_helper
  """
  def router_helper do
    Module.concat(router(), Helpers)
  end

  @doc """
  Helper method ensuring router helper is properly configured
  """
  def router_helper_configured? do
    router() && endpoint()
  end

  @doc """
  Wrapper for getting the application config of :send_address
  """
  def send_address do
    Application.get_env(:sentinel, :send_address)
  end

  @doc """
  Wrapper for getting the application config of :send_emails.
  Defaults to true
  Used by Sentinel to know if the application should actually send emails in the environment
  you're operating in
  """
  def send_emails? do
    Application.get_env(:sentinel, :send_emails, true)
  end

  @doc """
  Retrieves list of tuples of {ueberauth_provider, auth_url}
  """
  def ueberauth_providers do
    :ueberauth
    |> Application.get_all_env
    |> ueberauth_env_filter
    |> Enum.filter(fn provider_config ->
      {provider, _config} = provider_config
      provider != :identity
    end)
    |> Enum.map(fn provider_config ->
      {provider, _details} = provider_config
      %{provider: Atom.to_string(provider), url: router_helper().auth_url(endpoint(), :request, provider)}
    end)
  end

  defp ueberauth_env_filter([head|tail]) do
    {module, _other} = head
    if module == Ueberauth do
      ueberauth_env_filter(head)
    else
      ueberauth_env_filter(tail)
    end
  end
  defp ueberauth_env_filter({_module, [providers: ueberauth_config]}) do
    ueberauth_config
  end

  @doc """
  Wrapper for getting the application config of :user_model
  """
  def user_model do
    Application.get_env(:sentinel, :user_model)
  end

  @doc """
  Wrapper for getting the application config of :user_model_validator
  """
  def user_model_validator do
    Application.get_env(:sentinel, :user_model_validator)
  end

  ### View configs
  #
  @doc """
  Wrapper for getting the application config of :layout_view
  """
  def layout_view do
    Application.get_env(:sentinel, :layout_view, Sentinel.LayoutView)
  end

  @doc """
  Wrapper for getting the application config of :layout
  """
  def layout do
    Application.get_env(:sentinel, :layout, :app)
  end

  def lockable? do
    Application.get_env(:sentinel, :lockable, true)
  end

  def otp_app do
    Application.get_env(:sentinel, :otp_app)
  end

  @doc """
  Wrapper for getting and merging the application config of :views
  """
  def views do
    Map.merge(default_views(), custom_views())
  end

  defp default_views do
    %{
      email: Sentinel.EmailView,
      error: Sentinel.ErrorView,
      password: Sentinel.PasswordView,
      session: Sentinel.SessionView,
      shared: Sentinel.SharedView,
      unlock: Sentinel.UnlockView,
      user: Sentinel.UserView
    }
  end

  defp custom_views do
    Application.get_env(:sentinel, :views, %{})
  end

  @doc """
  Wrapper for getting the application config of :registrator_callback
  """
  def registrator_callback do
    Application.get_env(:sentinel, :registrator_callback)
  end

  @doc """
  Wrapper for getting the application config of :redirects
  """
  def redirects do
    Map.merge(default_redirects(), custom_redirects())
  end

  defp default_redirects do
    %{
      password_create: "/",
      password_update: {:account, :edit},
      password_update_error: "/",
      password_update_unsuccessful: {:password, :new},
      session_create: {:account, :edit},
      session_create_error: {:auth, :new},
      session_delete: "/",
      user_confirmation: "/",
      user_confirmation_error: "/",
      user_confirmation_sent: "/",
      user_create: {:account, :edit},
      user_create_unconfirmed: "/",
      user_invitation: {:account, :edit},
      user_invitation_error: "/",
      user_invited: {:user, :new},
      unlock_account: "/",
      unlock_account_error: "/",
      unlock_create: "/",
    }
  end

  defp custom_redirects do
    Application.get_env(:sentinel, :redirects, %{})
  end
end
