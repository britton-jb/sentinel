defmodule Html.ConfirmationTest do
  use Sentinel.TestCase
  use Plug.Test
  use Phoenix.ConnTest

  import RouterHelper
  import HtmlRequestHelper
  alias Sentinel.Registrator
  alias Sentinel.Confirmator

  @email "user@example.com"
  @password "secret"

  setup do
    #user = Forge.saved_user
    user = Sentinel.TestRepo.insert!(%Sentinel.User{
      email: "test@example.com",
      confirmed_at: Ecto.DateTime.utc,
      hashed_password: Sentinel.Util.crypto_provider.hashpwsalt("password")
    })

    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end

    {:ok, %{user: user}}
  end

  test "get new confirmation instructions page" do
    conn = call(Sentinel.TestRouter, :get, "/confirmation_instructions")
    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Resend confirmation instructions")
  end

  test "confirm user with a bad token" do
    {_, changeset} = Registrator.changeset(%{email: @email, password: @password})
                      |> Confirmator.confirmation_needed_changeset
    user = Sentinel.Util.repo.insert!(changeset)

    conn = call(Sentinel.TestRouter, :post, "/users/confirm", %{email: user.email, confirmation_token: "bad_token"})
    assert conn.status == 422
  end

  test "confirm a user" do
    {token, changeset} = Registrator.changeset(%{email: @email, password: @password})
                          |> Confirmator.confirmation_needed_changeset
    user = Sentinel.Util.repo.insert!(changeset)

    conn = call(Sentinel.TestRouter, :post, "/users/confirm", %{email: user.email, confirmation_token: token})
    assert conn.status == 201

    updated_user = Sentinel.Util.repo.get! Sentinel.UserHelper.model, user.id

    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.confirmed_at != nil
  end

  test "confirm a user's new email" do
    {token, changeset} = Registrator.changeset(%{email: @email, password: @password})
                         |> Confirmator.confirmation_needed_changeset
    user =
      Sentinel.Util.repo.insert!(changeset)
      |> Confirmator.confirmation_changeset(%{"confirmation_token" => token})
      |> Sentinel.TestRepo.update!

    {token, changeset} = Sentinel.AccountUpdater.changeset(user, %{"email" => "new@example.com"})
    new_email_user = Sentinel.TestRepo.update!(changeset)

    conn = call(Sentinel.TestRouter, :post, "/users/confirm", %{email: new_email_user.email, confirmation_token: token})
    assert conn.status == 201

    updated_user = Sentinel.Util.repo.get! Sentinel.UserHelper.model, user.id
    assert updated_user.hashed_confirmation_token == nil
    assert updated_user.unconfirmed_email == nil
    assert updated_user.email == "new@example.com"
  end
end
