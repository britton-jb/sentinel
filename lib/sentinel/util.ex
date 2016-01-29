defmodule Sentinel.Util do
  import Plug.Conn
  import Phoenix.Controller

  def repo do
    Application.get_env(:sentinel, :repo)
  end

  def crypto_provider do
    Application.get_env(:sentinel, :crypto_provider, Comeonin.Bcrypt)
  end

  def send_error(conn, error, status \\ 422) do
    conn
    |> put_status(status)
    |> json %{errors: error}
  end

  def presence_validator(field, nil), do: [{field, "can't be blank"}]
  def presence_validator(field, ""), do: [{field, "can't be blank"}]
  def presence_validator(_field, _), do: []
end
