defmodule Sentinel.RouterHelper do
  def helpers do
    Module.concat(Application.get_env(:sentinel, :router), Helpers)
  end

  def endpoint do
    Application.get_env(:sentinel, :endpoint)
  end

  def configured? do
    Application.get_env(:sentinel, :router) && endpoint
  end
end
