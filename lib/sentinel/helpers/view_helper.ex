defmodule Sentinel.ViewHelper do
  def user_view do
    Application.get_env(:sentinel, :user_view)
  end
end
