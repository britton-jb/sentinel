defmodule UeberauthTest do
  use Sentinel.UnitCase

  #alias Sentinel.Ueberauth

  test "identity changeset validates presence of password when invitable is false" do
    Mix.Config.persist([sentinel: [invitable: false]])

    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :identity})
    assert changeset.errors[:password] == {"can't be blank", []}

    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :identity, uid: "1", password: ""})
    assert changeset.errors[:password] == {"can't be blank", []}

    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :identity, uid: "1", password: nil})
    assert changeset.errors[:password] == {"can't be blank", []}
  end

  test "identity changeset does not validates presence of password when invitable is true" do
    Mix.Config.persist([sentinel: [invitable: true]])

    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :identity, uid: "1"})
    refute changeset.errors[:password] == {"can't be blank", []}

    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :identity, uid: "1", password: ""})
    refute changeset.errors[:password] == {"can't be blank", []}

    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :identity, uid: "1", password: nil})
    refute changeset.errors[:password] == {"can't be blank", []}
  end

  test "identity changeset includes the hashed password if valid" do
    user = Factory.insert(:user)
    params = %{
      provider: :identity,
      credentials: %{
        other: %{
          password: "password",
          password_confirmation: "password",
        }
      }
    }

    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{user_id: user.id, uid: to_string(user.id)}, params)

    hashed_pw = Ecto.Changeset.get_change(changeset, :hashed_password)
    assert Sentinel.Config.crypto_provider.checkpw(params.credentials.other.password, hashed_pw)
  end

  test "identity changeset does not include the hashed password if invalid" do
    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{"password" => "secret"})

    hashed_pw = Ecto.Changeset.get_change(changeset, :hashed_password)
    assert hashed_pw == nil
  end

  test "identity changeset is invalid if user_id is not set" do
    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :identity, uid: "1"})
    assert changeset.errors[:user_id] == {"can't be blank", [validation: :required]}
  end

  test "non-identity changeset cannont have password reset token" do
    hashed_password_reset_token =
      Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :facebook})
      |> Ecto.Changeset.get_field(:hashed_password_reset_token, nil)

    assert is_nil(hashed_password_reset_token)
  end

  test "non-identity changeset must include uid" do
    changeset = Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, %{provider: :facebook})
    assert changeset.errors[:uid] == {"can't be blank", [validation: :required]}
  end
end