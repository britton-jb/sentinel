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
  Wrapper for getting the application config of :auth_handler
  """
  def auth_handler do
    Application.get_env(:sentinel, :auth_handler, Sentinel.AuthHandler)
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
  Wrapper for getting the application config of :error_view
  """
  def error_view do
    Application.get_env(:sentinel, :error_view, Sentinel.ErrorView)
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
    invitable && invitation_registration_url
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
  Wrapper for getting the application config of :reply_to, defaults to the send_address
  """
  def reply_to do
    Application.get_env(:sentinel, :reply_to, send_address)
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
    Module.concat(router, Helpers)
  end

  @doc """
  Helper method ensuring router helper is properly configured
  """
  def router_helper_configured? do
    router && endpoint
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
      {Atom.to_string(provider), router_helper.auth_url(endpoint, :request, provider)}
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

  @doc """
  Wrapper for getting the application config of :user_view
  """
  def user_view do
    Application.get_env(:sentinel, :user_view, Sentinel.UserView)
  end

  def layout_view do
    Application.get_env(:sentinel, :layout_view, Sentinel.LayoutView)
  end

  def layout do
    Application.get_env(:sentinel, :layout, :app)
  end

  @doc """
  Wrapper for getting the application config of :registrator_callback
  """
  def registrator_callback do
    Application.get_env(:sentinel, :registrator_callback, {Sentinel.RegistratorCallback, :run})
  end
end
