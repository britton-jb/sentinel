defmodule Sentinel.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "virtual_session_table" do
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
    |> Sentinel.Session.username_or_email_required
  end

  def username_or_email_required(changeset) do
    case fetch_change(changeset, :username) do
      {:ok, username} -> changeset
      :error ->
        case fetch_change(changeset, :email) do
          {:ok, email} -> changeset
          :error ->
            changeset
            |> add_error(:username, "Username or email address required")
            |> add_error(:email, "Username or email address required")
        end
    end
  end
end
