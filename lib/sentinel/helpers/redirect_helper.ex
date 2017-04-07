defmodule Sentinel.RedirectHelper do
  @moduledoc """
  Redirect helper for Sentinel
  """

  use Phoenix.Controller

  alias Sentinel.Config

  @doc """
  Redirect from a given context
  """
  def redirect_from(conn, context) do
    path =
      case Config.redirects()[context] do
        {controller, action} ->
          get_path(controller, action)
        path when is_binary(path) ->
          path
        _ ->
          "/"
      end

    redirect(conn, to: path)
  end

  defp get_path(controller, action) do
    try do
      apply(Config.router_helper(), :"#{controller}_path", [Config.endpoint, action])
    rescue
      _ -> "/"
    end
  end
end
