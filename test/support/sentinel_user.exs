defmodule Sentinel.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field  :email,                       :string
    field  :username,                    :string
    field  :role,                        :string
    field  :hashed_confirmation_token,   :string
    field  :confirmed_at,                Ecto.DateTime
    field  :unconfirmed_email,           :string
  end

  @required_fields ~w()
  @optional_fields ~w(email username role hashed_confirmation_token confirmed_at unconfirmed_email)

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> username_or_email_required
    |> downcase_email
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def permissions(_user_id) do
    Application.get_env(:sentinel, :permissions)
  end

  defp downcase_email(changeset) do
    email = get_change(changeset, :email)
    if is_nil(email) do
      changeset
    else
      put_change(changeset, :email, String.downcase(email))
    end
  end

  defp username_or_email_required(changeset) do
    case fetch_field(changeset, :username) do
      {_data_or_changes, _username} -> changeset
      _error ->
        case fetch_field(changeset, :email) do
          {_data_or_changes, _email} -> changeset
          _error ->
            changeset = add_error(changeset, :username, "Username or email address required")
            add_error(changeset, :email, "Username or email address required")
        end
    end
  end
end
