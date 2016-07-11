defmodule Sentinel.Util do
  import Plug.Conn
  import Phoenix.Controller

  def repo do
    Application.get_env(:sentinel, :repo)
  end

  def crypto_provider do
    Application.get_env(:sentinel, :crypto_provider, Comeonin.Bcrypt)
  end

  def send_error(conn, changeset_error, status \\ 422)
  def send_error(conn, changeset_error, status) when is_list(changeset_error) do
    errors =
      Enum.into(changeset_error, %{})
      |> Enum.map(fn{field, {message, _}} ->
        %{ field => message }
      end) |> List.wrap

    conn
    |> put_status(status)
    |> json(%{errors: errors})
  end
  def send_error(conn, changeset_error, status) do
    errors =
      Enum.map(changeset_error, fn{field, message} ->
        %{ field => message }
      end) |> List.wrap

    conn
    |> put_status(status)
    |> json(%{errors: errors})
  end

  def presence_validator(field, nil), do: [{field, "can't be blank"}]
  def presence_validator(field, ""), do: [{field, "can't be blank"}]
  def presence_validator(_field, _), do: []
end
