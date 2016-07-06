defmodule Sentinel.Util do
  import Plug.Conn
  import Phoenix.Controller

  def repo do
    Application.get_env(:sentinel, :repo)
  end

  def crypto_provider do
    Application.get_env(:sentinel, :crypto_provider, Comeonin.Bcrypt)
  end

  def format_errors(errors) when is_list(errors) do
    Enum.into(errors, %{})
    |> Enum.map(fn{field, {message, _}} ->
      %{ field => message }
    end) |> List.wrap
  end
  def format_errors(errors) do
    Enum.map(errors, fn{field, message} ->
      %{ field => message }
    end) |> List.wrap
  end

  def send_error(conn, changeset_error, status \\ 422)
  def send_error(conn, changeset_error, status) when is_list(changeset_error) do
    errors = Sentinel.Util.format_errors(changeset_error)

    Sentinel.Util.send_formatted_error(conn, errors, status)
  end
  def send_error(conn, changeset_error, status) do
    errors = Sentinel.Util.format_errors(changeset_error)

    Sentinel.Util.send_formatted_error(conn, errors, status)
  end

  def send_formatted_error(conn, errors, status \\ 422) do
    conn
    |> put_status(status)
    |> json(%{errors: errors})
  end

  def presence_validator(field, nil), do: [{field, "can't be blank"}]
  def presence_validator(field, ""), do: [{field, "can't be blank"}]
  def presence_validator(_field, _), do: []
end
