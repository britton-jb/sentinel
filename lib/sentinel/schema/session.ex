defmodule Sentinel.Session do
  @moduledoc """
  Virtual Session data model allowing us to have session changesets and HTML validations
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Sentinel.Session

  embedded_schema do
    field :username, :string
    field :email, :string
    field :password, :string
  end

  @required_fields ~w(password)
  @optional_fields ~w(username email)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> Session.email_or_username_required
  end

  @doc """
  Changeset validation ensuring that the user has either the username or email
  address defined
  """
  def email_or_username_required(changeset) do
    case fetch_change(changeset, :email) do
      {:ok, _email} -> changeset
      :error ->
        case fetch_change(changeset, :username) do
          {:ok, _username} -> changeset
          :error ->
            changeset
            |> add_error(:username, "Username or email address required")
            |> add_error(:email, "Username or email address required")
        end
    end
  end
end
