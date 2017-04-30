defmodule Sentinel.UserTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field  :email,                       :string, null: false
    field  :role,                        :string
    field  :hashed_confirmation_token,   :string
    field  :confirmed_at,                Ecto.DateTime
    field  :unconfirmed_email,           :string

    has_many :ueberauths, Sentinel.Ueberauth, on_delete: :delete_all
  end

  @required_fields [:email]
  @optional_fields [:role, :hashed_confirmation_token, :confirmed_at, :unconfirmed_email]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required([:email])
    |> downcase_email
    |> unique_constraint(:email)
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
end
