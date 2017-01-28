defmodule RegistratorTest do
  use Sentinel.UnitCase

  alias Sentinel.Changeset.Registrator

  setup do
    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end
  end

  @valid_params %{"email" => "unique@example.com"}
  @case_insensitive_valid_params %{"email" => "Unique@example.com"}

  test "changeset validates presence of email" do
    changeset = Registrator.changeset(%{})
    assert changeset.errors[:email] == {"can't be blank", [validation: :required]}

    changeset = Registrator.changeset(%{"email" => ""})
    assert changeset.errors[:email] == {"can't be blank", [validation: :required]}

    changeset = Registrator.changeset(%{"email" => nil})
    assert changeset.errors[:email] == {"can't be blank", [validation: :required]}
  end

  test "changeset validates uniqueness of email" do
    user = Factory.insert(:user)
    {:error, changeset} = Registrator.changeset(%{@valid_params | "email" => user.email})
                          |> TestRepo.insert

    assert changeset.errors[:email] == {"has already been taken", []}
  end

  test "changeset downcases email" do
    changeset = Registrator.changeset(@case_insensitive_valid_params)

    assert changeset.valid?
  end

  test "changeset runs user_model_validator from config" do
    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Ecto.Changeset.add_error(changeset, :email, "custom_error")
    end)
    changeset = Registrator.changeset(@valid_params)

    assert !changeset.valid?
    assert changeset.errors[:email] == {"custom_error", []}
  end
end
