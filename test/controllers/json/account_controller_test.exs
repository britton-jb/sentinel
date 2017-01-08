defmodule Json.AccountControllerTest do
  use Sentinel.ConnCase

  alias Ecto.Changeset
  alias Ecto.DateTime
  alias Sentinel.Ueberauthenticator
  alias Sentinel.User

  @from_email "test@example.com"
  @old_email "old@example.com"
  @new_email "user@example.com"
  @old_password "old_secret"
  @new_password "secret"

  defp old_email do
    "old@example.com"
  end

  setup do
    on_exit fn ->
      Application.delete_env :sentinel, :user_model_validator
    end

    user = Factory.insert(:user,
      email: old_email,
      confirmed_at: DateTime.utc,
    )
    ueberauth = Factory.insert(:ueberauth, user: user)
    permissions = User.permissions(user.id)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token, permissions)

    conn =
      build_conn
      |> Conn.put_req_header("content-type", "application/json")
      |> Conn.put_req_header("authorization", token)

    {:ok, %{user: user, auth: ueberauth, conn: conn}}
  end

  test "get current user account info", %{conn: conn} do
    conn = get conn, account_path(conn, :show)
    response = json_response(conn, 200)
    assert response["email"] == old_email
  end

  test "update email", %{conn: conn, user: user, auth: auth} do
    Mix.Config.persist([sentinel: [confirmable: :optional]])

    mocked_token = SecureRandom.urlsafe_base64()
    mocked_user = Map.merge(user, %User{unconfirmed_email: @new_email})
    mocked_mail = Mailer.send_new_email_address_email(mocked_user, mocked_token)

    with_mock Mailer, [:passthrough], [send_new_email_address_email: fn(_, _) -> mocked_mail end] do
      conn = put conn, account_path(conn, :update), %{account: %{email: @new_email}}
      response = json_response(conn, 200)

      assert response["email"] == @old_email
      assert response["unconfirmed_email"] == @new_email

      {:ok, _} = Ueberauthenticator.ueberauthenticate(%Ueberauth.Auth{
        uid: @old_email,
        provider: :identity,
        credentials: %Ueberauth.Auth.Credentials{
          other: %{password: auth.plain_text_password}
        }
      })
      assert_delivered_email mocked_mail
    end
  end

  test "set email to the same email it was before", %{conn: conn, user: user, auth: auth} do
    conn = put conn, account_path(conn, :update), %{account: %{email: @old_email}}
    response = json_response(conn, 200)

    assert response["email"] == @old_email
    {:ok, _} = Ueberauthenticator.ueberauthenticate(%Ueberauth.Auth{
      uid: @old_email,
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
    Application.put_env(:sentinel, :user_model_validator, fn changeset ->
      Changeset.add_error(changeset, :password, "too_short")
    end)

    conn = put conn, account_path(conn, :update), %{account: %{password: @new_password}}
    response = json_response(conn, 422)
    assert response == %{"errors" => [%{"password" => "too_short"}]} #FIXME this should be a better error
    {:ok, _} = Ueberauthenticator.ueberauthenticate(%Ueberauth.Auth{
      uid: @old_email,
      provider: :identity,
      credentials: %Ueberauth.Auth.Credentials{
        other: %{password: auth.plain_text_password}
      }
    })

    refute_delivered_email Sentinel.Mailer.NewEmailAddress.build(user, "token")
  end
end
