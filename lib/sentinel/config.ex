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
    #FIXME provide a default one of these?
    Application.get_env(:sentinel, :error_view)
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
    #FIXME raise on this if not configured?
    router && endpoint
  end

  @doc """
  Wrapper for getting the application config of :send_address
  """
  def send_address do
    #FIXME raise on this if not configured?
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
    #FIXME provide a default of these?
    Application.get_env(:sentinel, :user_view)
  end
end
