defmodule Sentinel.RedirectHelper do
  @moduledoc """
  Redirect helper for Sentinel
  """

  use Phoenix.Controller

  alias Sentinel.Config

  @spec api_redirect(%Plug.Conn{}, atom, map) :: %Plug.Conn{}
  def api_redirect(conn, redirect, params \\ %{}) do
    redirect(conn, external: "#{Map.get(Config.redirects(), redirect)}#{mapped_params(params)}")
  end
  defp mapped_params(%{} = _params), do: nil
  defp mapped_params(params) do
    param_string =
      params
      |> Enum.map_join("&", fn({key, value}) ->
        "#{key}=#{value}"
      end)

    "?#{param_string}"
  end

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
    apply(Config.router_helper(), :"#{controller}_path", [Config.endpoint, action])
  rescue
      _ -> "/"
  end
end
