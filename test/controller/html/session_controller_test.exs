defmodule Html.SessionControllerTest do
  use Sentinel.TestCase
  use Plug.Test
  use Phoenix.ConnTest

  import RouterHelper
  import HtmlRequestHelper
  alias Sentinel.TestRouter
  alias Sentinel.Registrator
  alias Sentinel.Confirmator
  import Sentinel.Util
  alias Mix.Config

  @email "user@example.com"
  @odd_case_email "User@example.com"
  @username "user@example.com"
  @password "secret"
  @role "user"

  test "get login page" do
    conn = call(TestRouter, :get, "/sessions")
    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Log in")
  end

  test "sign in with unknown email" do
    conn = call(TestRouter, :post, "/sessions", %{password: @password, email: @email})
    assert conn.status == 401
  end

  test "sign in with wrong password" do
    Registrator.changeset(%{email: @email, password: @password})
    |> repo.insert!

    conn = call(TestRouter, :post, "/sessions", %{password: "wrong", email: @email})
    assert conn.status == 401
  end

  test "sign in as unconfirmed user - confirmable default/optional" do
    Config.persist([sentinel: [confirmable: :optional]])

    {_, changeset} = Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                      |> Confirmator.confirmation_needed_changeset
    repo.insert!(changeset)

    conn = call(TestRouter, :post, "/sessions", %{password: @password, email: @email})
    assert conn.status == 302
  end

  test "sign in as unconfirmed user - confirmable false" do
    Config.persist([sentinel: [confirmable: :false]])

    {_, changeset} = Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                      |> Confirmator.confirmation_needed_changeset
    repo.insert!(changeset)

    conn = call(TestRouter, :post, "/sessions", %{password: @password, email: @email})
    assert conn.status == 302
  end

  test "sign in as unconfirmed user - confirmable required" do
    Config.persist([sentinel: [confirmable: :required]])

    {_, changeset} = Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                      |> Confirmator.confirmation_needed_changeset
    repo.insert!(changeset)

    conn = call(TestRouter, :post, "/sessions", %{password: @password, email: @email})
    assert conn.status == 401
  end

  test "sign in as confirmed user with email" do
    Registrator.changeset(%{"email" => @email, "password" => @password, "role" => @role})
                                      |> Ecto.Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
                                      |> repo.insert!

    conn = call(TestRouter, :post, "/sessions", %{password: @password, email: @email})
    assert conn.status == 302
  end

  test "sign in as confirmed user with email - case insensitive" do
    Registrator.changeset(%{"email" => @odd_case_email, "password" => @password, "role" => @role})
                                      |> Ecto.Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
                                      |> repo.insert!

    conn = call(TestRouter, :post, "/sessions", %{password: @password, email: String.upcase(@odd_case_email)})
    assert conn.status == 302
  end

  test "sign in with unknown username" do
    conn = call(TestRouter, :post, "/sessions", %{password: @password, username: @username})
    assert conn.status == 401
  end

  test "sign in with username and wrong password" do
    Registrator.changeset(%{"username" => @username, "password" => @password, "role" => @role})
                                        |> repo.insert!

    conn = call(TestRouter, :post, "/sessions", %{password: "wrong", username: @username})
    assert conn.status == 401
  end

  test "sign in user with username" do
    Registrator.changeset(%{"username" => @username, "password" => @password, "role" => @role})
                                        |> repo.insert!

    conn = call(TestRouter, :post, "/sessions", %{password: @password, username: @username})
    assert conn.status == 302
  end

  test "sign out" do
    user = Forge.saved_user
    Guardian.encode_and_sign(user, :token)

    conn = call_with_session(user, TestRouter, :delete, "/sessions")
    assert conn.status == 302
  end
end
