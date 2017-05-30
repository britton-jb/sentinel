defmodule Sentinel.Plug.AuthenticateResource do
  def init(opts \\ %{}) do
    {
      Guardian.Plug.VerifyHeader.init(opts),
      Guardian.Plug.VerifySession.init(opts),
      Guardian.Plug.EnsureAuthenticated.init(opts),
      Guardian.Plug.LoadResource.init(opts)
    }
  end

  def call(conn, {verify_header_opts, verify_session_opts, ensure_authenticated_opts, load_resource_opts}) do
    with %Plug.Conn{halted: false} = conn <- Guardian.Plug.VerifyHeader.call(conn, verify_header_opts),
         %Plug.Conn{halted: false} = conn <- Guardian.Plug.VerifySession.call(conn, verify_session_opts),
         %Plug.Conn{halted: false} = conn <- Guardian.Plug.EnsureAuthenticated.call(conn, ensure_authenticated_opts),
         %Plug.Conn{halted: false} = conn <- Guardian.Plug.LoadResource.call(conn, load_resource_opts) do
      conn
    else
      conn -> conn
    end
  end
end