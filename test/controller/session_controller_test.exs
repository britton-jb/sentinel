defmodule SessionControllerTest do
  use Sentinel.Case
  use Plug.Test
  import RouterHelper
  alias Sentinel.TestRouter
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  import Sentinel.Util
  alias Mix.Config

  @email "user@example.com"
  @username "user@example.com"
  @password "secret"
  @headers [{"content-type", "application/json"}]
  @role "user"

  test "sign in with unknown email" do
    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: %{base: "Unknown email or password"}})
  end

  test "sign in with wrong password" do
    Registrator.changeset(%{email: @email, password: @password})
    |> repo.insert!

    conn = call(TestRouter, :post, "/api/sessions", %{password: "wrong", email: @email}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: %{base: "Unknown email or password"}})
  end

  test "sign in as unconfirmed user - confirmable default/optional" do
    Config.persist([sentinel: [confirmable: :optional]])

    {_, changeset} = Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                      |> Confirmator.confirmation_needed_changeset
    repo.insert!(changeset)

    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 200
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token
  end

  test "sign in as unconfirmed user - confirmable false" do
    Config.persist([sentinel: [confirmable: :false]])

    {_, changeset} = Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                      |> Confirmator.confirmation_needed_changeset
    repo.insert!(changeset)

    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 200
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token
  end

  test "sign in as unconfirmed user - confirmable required" do
    Config.persist([sentinel: [confirmable: :required]])

    {_, changeset} = Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                      |> Confirmator.confirmation_needed_changeset
    repo.insert!(changeset)

    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: %{base: "Account not confirmed yet. Please follow the instructions we sent you by email."}})
  end

  test "sign in as confirmed user with email" do
    Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                                      |> Ecto.Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
                                      |> repo.insert!

    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 200
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token
  end

  test "sign in with unknown username" do
    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, username: @username}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: %{base: "Unknown email or password"}})
  end

  test "sign in with username and wrong password" do
    Registrator.changeset(%{"username" => @username, "password" => @password, "role" => @role})
                                        |> repo.insert!

    conn = call(TestRouter, :post, "/api/sessions", %{password: "wrong", username: @username}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: %{base: "Unknown email or password"}})
  end

  test "sign in user with username" do
    Registrator.changeset(%{"username" => @username, "password" => @password, "role" => @role})
                                        |> repo.insert!

    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, username: @username}, @headers)
    assert conn.status == 200
    %{"token" => token} = Poison.decode!(conn.resp_body)

    assert repo.one(GuardianDb.Token).jwt == token
  end

  test "sign out" do
    user = Sentinel.TestRepo.insert!(%Sentinel.User{
      email: "signout@example.com",
      confirmed_at: Ecto.DateTime.utc,
      hashed_password: Sentinel.Util.crypto_provider.hashpwsalt("password")
    })
    permissions = Sentinel.User.permissions(user.role)

    { :ok, token, _} = Guardian.encode_and_sign(user, :token, permissions)

    count = length(repo.all(GuardianDb.Token))
    conn = call(TestRouter, :delete, "/api/sessions", %{password: @password, username: @username}, [{"authorization", token} | @headers])
    assert conn.status == 200
    assert (count - 1) == length(repo.all(GuardianDb.Token))
  end
end
