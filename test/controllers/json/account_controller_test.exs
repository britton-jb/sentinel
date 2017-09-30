defmodule Json.AccountControllerTest do
  use Sentinel.ConnCase

  alias Ecto.Changeset
  alias Sentinel.Ueberauthenticator
  alias Sentinel.User

  @new_email "user@example.com"
  @new_password "secret"

  defp old_email do
    "old@example.com"
  end

  setup do
    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end

    user = Factory.insert(:user,
      email: old_email(),
      confirmed_at: DateTime.utc_now(),
    )
    ueberauth = Factory.insert(:ueberauth, user: user)
    {:ok, token, _} = Sentinel.Guardian.encode_and_sign(user)

    conn =
      build_conn()
      |> Conn.put_req_header("content-type", "application/json")
      |> Conn.put_req_header("authorization", "Bearer #{token}")

    {:ok, %{user: user, auth: ueberauth, conn: conn}}
  end

  test "get current user account info", %{conn: conn} do
    conn = get conn, api_account_path(conn, :show)
    response = json_response(conn, 200)
    assert response["email"] == old_email()
  end

  test "update email", %{conn: conn, user: user, auth: auth} do
    Mix.Config.persist([sentinel: [confirmable: :optional]])

    mocked_token = SecureRandom.urlsafe_base64()
    mocked_user = Map.merge(user, %User{unconfirmed_email: @new_email})
    mocked_mail = Mailer.NewEmailAddress.build(mocked_user, mocked_token)

    with_mock Mailer.NewEmailAddress, [:passthrough], [build: fn(_, _) -> mocked_mail end] do
      conn = put conn, api_account_path(conn, :update), %{account: %{email: @new_email}}
      response = json_response(conn, 200)

      assert response["email"] == old_email()
      assert response["unconfirmed_email"] == @new_email

      {:ok, _} = Ueberauthenticator.ueberauthenticate(%Ueberauth.Auth{
        uid: old_email(),
        provider: :identity,
        credentials: %Ueberauth.Auth.Credentials{
          other: %{password: auth.plain_text_password}
        }
      })
      assert_delivered_email mocked_mail
    end
  end

  test "set email to the same email it was before", %{conn: conn, user: user, auth: auth} do
    conn = put conn, api_account_path(conn, :update), %{account: %{email: old_email()}}
    response = json_response(conn, 200)

    assert response["email"] == old_email()
    {:ok, _} = Ueberauthenticator.ueberauthenticate(%Ueberauth.Auth{
      uid: old_email(),
      provider: :identity,
      credentials: %Ueberauth.Auth.Credentials{
        other: %{password: auth.plain_text_password}
      }
    })

    reloaded_user = TestRepo.get(User, user.id)
    assert reloaded_user.unconfirmed_email == nil

    refute_delivered_email Sentinel.Mailer.NewEmailAddress.build(user, "token")
  end

  test "update account with custom validations", %{conn: conn, user: user, auth: auth} do
    params = %{account: %{password: @new_password}}

    Application.put_env(:sentinel, :user_model_validator, fn (changeset, _params) ->
      Changeset.add_error(changeset, :password, "too_short")
    end)

    conn = put conn, api_account_path(conn, :update), params
    response = json_response(conn, 422)
    assert response == %{"errors" => [%{"password" => "too_short"}]}
    {:ok, _} = Ueberauthenticator.ueberauthenticate(%Ueberauth.Auth{
      uid: old_email(),
      provider: :identity,
      credentials: %Ueberauth.Auth.Credentials{
        other: %{password: auth.plain_text_password}
      }
    })

    refute_delivered_email Sentinel.Mailer.NewEmailAddress.build(user, "token")
  end
end
