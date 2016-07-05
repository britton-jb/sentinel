defmodule Sentinel.User do
  use Ecto.Schema

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
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> Ecto.Changeset.cast(params, @required_fields ++ @optional_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
  end

  def permissions(_role) do
    Application.get_env(:sentinel, :permissions)
  end
end
