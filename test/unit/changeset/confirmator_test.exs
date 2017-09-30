defmodule ConfirmatorTest do
  use Sentinel.UnitCase

  import Mock

  alias Sentinel.Changeset.Confirmator

  test "confirmation_needed_changeset adds the hashed token" do
    {token, user} =
      Factory.build(:user)
      |> Ecto.Changeset.cast(%{}, [])
      |> Confirmator.confirmation_needed_changeset()
    hashed_confirmation_token = Ecto.Changeset.get_change(user, :hashed_confirmation_token)

    assert Config.crypto_provider.checkpw(token, hashed_confirmation_token)
  end

  test "confirmation_changeset adds an error if the token does not match" do
    {_token, user} =
      Factory.build(:user, hashed_confirmation_token: "123secret")
      |> Ecto.Changeset.cast(%{}, [])
      |> Confirmator.confirmation_needed_changeset
    user = Ecto.Changeset.apply_changes(user)

    changeset = Confirmator.confirmation_changeset(user, %{"confirmation_token" => "wrong"})

    assert !changeset.valid?
    assert changeset.errors[:confirmation_token] == {"invalid", []}
  end

  test "confirmation_changeset clears the saved token and sets confirmed at if the token matches" do
    mocked_date = DateTime.utc_now()
    with_mock DateTime, [:passthrough], [utc_now: fn -> mocked_date end] do
      {token, user} =
        Factory.build(:user, hashed_confirmation_token: "123secret")
        |> Ecto.Changeset.cast(%{}, [])
        |> Confirmator.confirmation_needed_changeset
      user = Ecto.Changeset.apply_changes(user)

      changeset = Confirmator.confirmation_changeset(user, %{"confirmation_token" => token})

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :hashed_confirmation_token, :not_here) == nil
      assert Ecto.Changeset.get_change(changeset, :confirmed_at) == mocked_date
    end
  end
end
