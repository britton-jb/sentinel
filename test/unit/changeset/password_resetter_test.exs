defmodule PasswordResetterTest do
  use Sentinel.UnitCase

  alias Sentinel.Changeset.PasswordResetter

  setup do
    params = %{
      credentials: %{
        other: %{
          password: "password",
          password_confirmation: "password"
        }
      },
      password_reset_token: "token"
    }
    {:ok, %{params: params}}
  end

  test "create_changeset/nil should returns invalid changeset" do
    {nil, changeset} = PasswordResetter.create_changeset(nil)
    refute changeset.valid?
  end

  test "create_changeset/1 with sentinel.ueberauth model struct returns a token and a valid changeset in a tuple" do
    {token, changeset} = PasswordResetter.create_changeset(%Sentinel.Ueberauth{
      provider: "identity"
    })
    refute is_nil(token)
    assert changeset.valid?
  end

  test "reset_changeset/2 without sentinel.ueberauth model struct returns invalid changeset", %{params: params} do
    changeset = PasswordResetter.reset_changeset(nil, params)
    refute changeset.valid?
  end

  test "reset_changeset/2 with sentinel.ueberauth model struct returns valid changset", %{params: params} do
    ueberauth_struct = %Sentinel.Ueberauth{
      provider: "identity",
      hashed_password_reset_token: Sentinel.Config.crypto_provider.hashpwsalt("token")
    }

    changeset = PasswordResetter.reset_changeset(ueberauth_struct, params)
    assert changeset.valid?
    refute changeset.changes |> Map.get(:hashed_password) |> is_nil
  end

  test "reset_changeset/2 with ueberauth model struct retursn invalid changeset when creating a new password without a password confirmation" do
    auth = %Sentinel.Ueberauth{
      hashed_password: "$2b$04$zx78eyMSingslyg5Q8Ay4.1qkrWkIFVKT8XUFBDJPpu2WH.2uBaGq",
      hashed_password_reset_token: "$2b$04$89K4euxPq3T3eYPLPZN7luYIf9jx4iwGvevEKLt17IGuSy4EvtKvK",
      id: 2421,
      provider: "identity",
      uid: nil,
      user_id: 2895
    }
    params = %{
      credentials: %{other: %{password: "new_password", password_confirmation: nil}},
      password_reset_token: "ZWbyIWHHEpA1rFp0vIt2lSj9pRCwJ7XqT7EOMcwkVxzx3d5md3HcgztoRXvHByuo0hVeF6krVvj6MwqJ56-s9A"
    }
    changeset = PasswordResetter.reset_changeset(auth, params)

    refute changeset.valid?
  end

  test "reset_changeset/2 with ueberauth model struct returns valid changeset when creating a new password with matching password and confirmation" do
    hashed_password = "$2b$04$zx78eyMSingslyg5Q8Ay4.1qkrWkIFVKT8XUFBDJPpu2WH.2uBaGq"

    auth = %Sentinel.Ueberauth{
      hashed_password: hashed_password,
      hashed_password_reset_token: "$2b$04$89K4euxPq3T3eYPLPZN7luYIf9jx4iwGvevEKLt17IGuSy4EvtKvK",
      id: 2421,
      provider: "identity",
      uid: nil,
      user_id: 2895
    }
    params = %{
      credentials: %{other: %{password: "new_password", password_confirmation: "new_password"}},
      password_reset_token: "ZWbyIWHHEpA1rFp0vIt2lSj9pRCwJ7XqT7EOMcwkVxzx3d5md3HcgztoRXvHByuo0hVeF6krVvj6MwqJ56-s9A"
    }

    changeset = PasswordResetter.reset_changeset(auth, params)
    assert changeset.valid?
    assert {:ok, nil} == Ecto.Changeset.fetch_change(changeset, :hashed_password_reset_token)
    refute is_nil(changeset.changes.hashed_password)
    refute changeset.changes.hashed_password == hashed_password
  end
end
