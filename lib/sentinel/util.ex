defmodule Sentinel.Util do
  @moduledoc """
  Utilities for sentinel to format errors and presence validation
  """
  import Phoenix.Controller
  import Plug.Conn

  alias Sentinel.Util

  @doc """
  Formats errors for sending via the API
  """
  def format_errors(errors) when is_list(errors) do
    errors
    |> Enum.into(%{})
    |> Enum.map(fn{field, {message, _}} ->
      %{field => message}
    end) |> List.wrap
  end
  def format_errors(errors) do
    errors
    |> Enum.map(fn{field, message} ->
      %{field => message}
    end) |> List.wrap
  end

  @doc """
  Sends unformatted errors via the API
  """
  def send_error(conn, changeset_error, status \\ 422)
  def send_error(conn, changeset_error, status) when is_list(changeset_error) do
    errors = Util.format_errors(changeset_error)

    Util.send_formatted_error(conn, errors, status)
  end
  def send_error(conn, changeset_error, status) do
    errors = Util.format_errors(changeset_error)

    Util.send_formatted_error(conn, errors, status)
  end

  @doc """
  Sends formatted errors via the API
  """
  def send_formatted_error(conn, errors, status \\ 422) do
    conn
    |> put_status(status)
    |> json(%{errors: errors})
  end

  @doc """
  Formats the parameters of a request to be used in a query string
  """
  def format_params(params) do
    params
    |> Map.keys
    |> Enum.map(fn(key) ->
      "#{key}=#{params[key]}"
    end)
    |> Enum.join("&")
  end

  def params_to_ueberauth_auth_struct(params, password_reset_token \\ nil) do
    %{
      password_reset_token: (password_reset_token || params["password_reset_token"]),
      credentials: %{
        other: %{
          password: params["password"],
          password_confirmation: params["password_confirmation"]
        }
      }
    }
  end

  @doc """
  Validates the presenced of a given field
  """
  def presence_validator(field, nil), do: [{field, "can't be blank"}]
  def presence_validator(field, ""), do: [{field, "can't be blank"}]
  def presence_validator(_field, _), do: []
end
