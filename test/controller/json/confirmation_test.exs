defmodule Json.ConfirmationTest do
  use Sentinel.TestCase
  use Plug.Test
  import RouterHelper
  alias Sentinel.TestRouter
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  alias Sentinel.AccountUpdater
  alias Sentinel.TestRepo
  import Sentinel.Util
  alias Sentinel.UserHelper

  @email "user@example.com"
  @password "secret"
  @headers [{"content-type", "application/json"}]

  test "confirm user with a bad token" do
    {_, changeset} = Registrator.changeset(%{email: @email, password: @password})
                      |> Confirmator.confirmation_needed_changeset
    repo.insert!(changeset)

    conn = call(TestRouter, :post, "/api/users/confirm", %{email: @email, confirmation_token: "bad_token"}, @headers)
    assert conn.status == 422
    assert conn.resp_body == Poison.encode!(%{errors: [%{confirmation_token: "invalid"}]})
  end

  test "confirm a user" do
    {token, changeset} = Registrator.changeset(%{email: @email, password: @password})
                          |> Confirmator.confirmation_needed_changeset
    user = repo.insert!(changeset)

    conn = call(TestRouter, :post, "/api/users/confirm", %{email: @email, confirmation_token: token}, @headers)
    assert conn.status == 200
    assert %{"email" => _email} = Poison.decode!(conn.resp_body)

    updated_user = repo.get! UserHelper.model, user.id

    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.confirmed_at != nil
  end

  test "confirm a user's new email" do
    {token, registrator_changeset} = Registrator.changeset(%{email: @email, password: @password})
                         |> Confirmator.confirmation_needed_changeset
    user =
      repo.insert!(registrator_changeset)
      |> Confirmator.confirmation_changeset(%{"confirmation_token" => token})
      |> TestRepo.update!

    {token, updater_changeset} = AccountUpdater.changeset(user, %{"email" => "new@example.com"})
    TestRepo.update!(updater_changeset)

    conn = call(TestRouter, :post, "/api/users/confirm", %{email: user.email, confirmation_token: token}, @headers)
    assert conn.status == 200
    assert %{"email" => _email} = Poison.decode!(conn.resp_body)

    updated_user = repo.get! UserHelper.model, user.id
    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.unconfirmed_email == nil
    assert updated_user.email == "new@example.com"
  end
end
