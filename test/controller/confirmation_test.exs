defmodule ConfirmationTest do
  use Sentinel.Case
  use Plug.Test
  import RouterHelper
  alias Sentinel.TestRouter
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  alias Sentinel.AccountUpdater
  alias Sentinel.TestRepo
  alias Sentinel.User
  import Sentinel.Util
  alias Sentinel.UserHelper

  @email "user@example.com"
  @password "secret"
  @headers [{"content-type", "application/json"}]

  setup_all do
    Mailman.TestServer.start
    :ok
  end

  test "confirm user with a bad token" do
    {_, changeset} = Registrator.changeset(%{email: @email, password: @password})
                      |> Confirmator.confirmation_needed_changeset
    user = repo.insert!(changeset)

    conn = call(TestRouter, :post, "/api/users/#{user.id}/confirm", %{confirmation_token: "bad_token"}, @headers)
    assert conn.status == 422
    assert conn.resp_body == "{\"errors\":{\"confirmation_token\":\"invalid\"}}"
  end

  test "confirm a user" do
    {token, changeset} = Registrator.changeset(%{email: @email, password: @password})
                          |> Confirmator.confirmation_needed_changeset
    user = repo.insert!(changeset)

    conn = call(TestRouter, :post, "/api/users/#{user.id}/confirm", %{confirmation_token: token}, @headers)
    assert conn.status == 200
    {:ok, session_token} = Poison.decode!(conn.resp_body) |> Dict.fetch("token")

    updated_user = repo.get! UserHelper.model, user.id

    assert session_token == repo.one(GuardianDb.Token).jwt
    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.confirmed_at != nil
  end

  test "confirm a user's new email" do
    {token, changeset} = Registrator.changeset(%{email: @email, password: @password})
                         |> Confirmator.confirmation_needed_changeset
    user = repo.insert!(changeset)

    Confirmator.confirmation_changeset(user, %{"confirmation_token" => token})
    |> TestRepo.update!

    user = TestRepo.one(User)
    {token, changeset} = AccountUpdater.changeset(user, %{"email" => "new@example.com"})
    user = TestRepo.update!(changeset)

    conn = call(TestRouter, :post, "/api/users/#{user.id}/confirm", %{confirmation_token: token}, @headers)
    assert conn.status == 200

    session_token = Poison.decode!(conn.resp_body)
            |> Dict.fetch!("token")

    assert session_token == repo.one(GuardianDb.Token).jwt
    updated_user = repo.get! UserHelper.model, user.id
    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.unconfirmed_email == nil
    assert updated_user.email == "new@example.com"
  end
end
