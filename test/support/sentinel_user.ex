defmodule Sentinel.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field  :email,                       :string
    field  :username,                    :string
    field  :role,                        :string
    field  :hashed_password,             :string
    field  :hashed_confirmation_token,   :string
    field  :confirmed_at,                Ecto.DateTime
    field  :hashed_password_reset_token, :string
    field  :unconfirmed_email,           :string
  end

  @required_fields ~w()
  @optional_fields ~w(email username role hashed_password hashed_confirmation_token confirmed_at hashed_password_reset_token unconfirmed_email)

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> username_or_email_required
  end

  def permissions(_role) do
    Application.get_env(:sentinel, :permissions)
  end

  defp username_or_email_required(changeset) do
    case fetch_change(changeset, :username) do
      {:ok, username} -> changeset
      :error ->
        case fetch_change(changeset, :email) do
          {:ok, email} -> changeset
          :error ->
            changeset = add_error(changeset, :username, "Username or email address required")
            add_error(changeset, :email, "Username or email address required")
        end
    end
  end
end
