defmodule Sentinel.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field  :email,                       :string
    field  :role,                        :string
    field  :hashed_confirmation_token,   :string
    field  :confirmed_at,                :utc_datetime
    field  :unconfirmed_email,           :string
    field  :my_attr,                     :string, virtual: true

    has_many :ueberauths, Sentinel.Ueberauth, on_delete: :delete_all
  end

  @required_fields [:email]
  @optional_fields [:role, :hashed_confirmation_token, :confirmed_at, :unconfirmed_email]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required([:email])
    |> Sentinel.Changeset.Schema.changeset
    |> unique_constraint(:email)
  end
end
