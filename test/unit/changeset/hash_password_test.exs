defmodule HashPasswordTest do
  use Sentinel.UnitCase

  alias Mix.Config
  alias Sentinel.Changeset.HashPassword

  setup do
    password = "password"
    matching = %{
      credentials: %{
        other: %{
          password: password,
          password_confirmation: password
        }
      }
    }

    mismatch = %{
      credentials: %{
        other: %{
          password: password,
          password_confirmation: "wrong password"
        }
      }
    }

    no_confirmation = %{
      credentials: %{
        other: %{
          password: password,
        }
      }
    }

    no_password = %{
      credentials: %{
        other: %{
        }
      }
    }

    {:ok, %{matching: matching, mismatch: mismatch, no_confirmation: no_confirmation, no_password: no_password}}
  end

  test "it should return a valid changeset with a hashed password when password and confirmation are present and match", %{matching: params} do
    assert %Sentinel.Ueberauth{}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> HashPassword.changeset(params)
      |> Map.get(:valid?)
  end

  test "it should return an invalid changeset without a hashed password when password and confirmation are present and match, and errors are already present", %{matching: params} do
    refute %Sentinel.Ueberauth{}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> Ecto.Changeset.add_error(:misc, "doesn't matter what this is")
      |> HashPassword.changeset(params)
      |> Map.get(:changes)
      |> Map.get(:hashed_password, false)
  end

  test "on creation it should return an invalid changeset when password and password confirmation do not match, and invitable is disabled", %{mismatch: params} do
    Config.persist([sentinel: [invitable: false ]])

    refute %Sentinel.Ueberauth{}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> HashPassword.changeset(params)
      |> Map.get(:valid?)
  end

  test "on update it should return a valid changeset when password and password confirmation do not match", %{mismatch: params} do
    assert %Sentinel.Ueberauth{id: 1}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> HashPassword.changeset(params)
      |> Map.get(:valid?)
  end

  test "it should return a valid changeset when password and password confirmation do not match and invitable module is enabled, and user is being created", %{mismatch: params} do
    Config.persist([sentinel: [invitable: true]])

    assert %Sentinel.Ueberauth{}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> HashPassword.changeset(params)
      |> Map.get(:valid?)
  end

  test "it should return an invalid changest when password is absent when invitable is disabled", %{no_password: params} do
    Config.persist([sentinel: [invitable: false]])

    refute %Sentinel.Ueberauth{}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> HashPassword.changeset(params)
      |> Map.get(:valid?)
  end

  test "on update it should return an invalid changest when password is absent an ueberauth struct", %{no_confirmation: params} do
    refute %Sentinel.Ueberauth{id: 1}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> HashPassword.changeset(params)
      |> Map.get(:valid?)
  end

  test "it should return a valid changeset if changes are unrelated to password", %{no_password: params} do
    assert %Sentinel.Ueberauth{id: 1}
      |> Ecto.Changeset.cast(%{}, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id])
      |> HashPassword.changeset(params)
      |> Map.get(:valid?)
  end
end
