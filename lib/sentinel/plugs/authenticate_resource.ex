defmodule Sentinel.Plug.AuthenticateResource do
  def init(opts \\ %{}) do
    Guardian.Plug.VerifyHeader.init()
    Guardian.Plug.EnsureAuthenticated.init(opts)
    Guardian.Plug.LoadResource.init()
  end

  def call(conn, opts) do
    with conn = %Plug.Conn{halted: false} <- Guardian.Plug.VerifyHeader.call(conn, %{}),
         conn = %Plug.Conn{halted: false} <- Guardian.Plug.EnsureAuthenticated.call(conn, opts),
         conn = %Plug.Conn{halted: false} <- Guardian.Plug.LoadResource.call(conn, %{}) do
      conn
    else
      conn -> conn
    end
  end
end