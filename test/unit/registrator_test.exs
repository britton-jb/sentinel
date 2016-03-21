defmodule RegistratorTest do
  use Sentinel.Case
  import Sentinel.Util
  alias Sentinel.Registrator
  alias Sentinel.TestRepo
  alias Mix.Config

  setup do
    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end
  end

  @valid_params %{"password" => "secret", "email" => "unique@example.com"}
  @valid_username_params %{"password" => "secret", "username" => "unique@example.com"}

  test "changeset validates presence of email" do
    changeset = Registrator.changeset(%{})
    assert changeset.errors[:email] == "can't be blank"

    changeset = Registrator.changeset(%{"email" => ""})
    assert changeset.errors[:email] == "can't be blank"

    changeset = Registrator.changeset(%{"email" => nil})
    assert changeset.errors[:email] == "can't be blank"
  end

  test "changeset validates presence of password when invitable is false" do
    Config.persist([sentinel: [invitable: false]])

    changeset = Registrator.changeset(%{"email" => "user@example.com"})
    assert changeset.errors[:password] == "can't be blank"

    changeset = Registrator.changeset(%{"email" => "user@example.com", "password" => ""})
    assert changeset.errors[:password] == "can't be blank"

    changeset = Registrator.changeset(%{"email" => "user@example.com", "password" => nil})
    assert changeset.errors[:password] == "can't be blank"
  end

  test "changeset does not validates presence of password when invitable is true" do
    Config.persist([sentinel: [invitable: true]])

    changeset = Registrator.changeset(%{"email" => "user@example.com"})
    assert Enum.empty?(changeset.errors)

    changeset = Registrator.changeset(%{"email" => "user@example.com", "password" => ""})
    assert Enum.empty?(changeset.errors)

    changeset = Registrator.changeset(%{"email" => "user@example.com", "password" => nil})
    assert Enum.empty?(changeset.errors)
  end

  test "changeset validates uniqueness of email" do
    user = Forge.saved_user
    {:error, changeset} = Registrator.changeset(%{@valid_params | "email" => user.email})
                          |> TestRepo.insert

    assert changeset.errors[:email] == "has already been taken"
  end

  test "changeset includes the hashed password if valid" do
    changeset = Registrator.changeset(@valid_params)

    hashed_pw = Ecto.Changeset.get_change(changeset, :hashed_password)
    assert crypto_provider.checkpw(@valid_params["password"], hashed_pw)
  end

  test "changeset does not include the hashed password if invalid" do
    changeset = Registrator.changeset(%{"password" => "secret"})

    hashed_pw = Ecto.Changeset.get_change(changeset, :hashed_password)
    assert hashed_pw == nil
  end

  test "changeset is valid with email and password" do
    changeset = Registrator.changeset(@valid_params)

    assert changeset.valid?
  end

  test "changeset runs user_model_validator from config" do
    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Ecto.Changeset.add_error(changeset, :email, "custom_error")
    end)
    changeset = Registrator.changeset(@valid_params)

    assert !changeset.valid?
    assert changeset.errors[:email] == "custom_error"
  end

  test "changeset is valid with username and password" do
    changeset = Registrator.changeset(@valid_username_params)

    assert changeset.valid?
  end
  test "changeset validates uniqueness of username" do
    user = Forge.saved_user
    {:error, changeset} = Registrator.changeset(%{@valid_username_params | "username" => user.username})
                          |> TestRepo.insert

    assert changeset.errors[:username] == "has already been taken"
  end
end
