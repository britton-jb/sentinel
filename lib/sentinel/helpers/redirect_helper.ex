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
    with {controller, action} <- Config.redirects()[context],
         path                 <- get_path(controller, action) do
      conn
      |> redirect(to: path)
    else
      _ ->
        conn
        |> redirect(to: "/")
    end
  end

  defp get_path(controller, action) do
    apply(Config.router_helper(), :"#{controller}_path", [Config.endpoint, action])
  end
end
