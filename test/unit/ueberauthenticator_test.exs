defmodule UeberauthenticatorTest do
  use Sentinel.UnitCase

  alias Mix.Config
  alias Sentinel.Ueberauthenticator
  alias Ueberauth.Auth

  setup do
    on_exit fn ->
      Config.persist([sentinel: [invitable: true]])
    end

    auth = Factory.insert(:ueberauth)
    confirmed_user = Factory.insert(:user, confirmed_at: Ecto.DateTime.utc)
    confirmed_auth = Factory.insert(:ueberauth, user: confirmed_user)
    {:ok,
      %{
        auth: auth,
        user: auth.user,
        confirmed_user: confirmed_user,
        confirmed_auth: confirmed_auth,
      }
    }
  end

  test "identity provider without user or passsword" do
    assert {:error, [email: {"can't be blank", [validation: :required]}]} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: nil
        }
      },
      uid: nil
    })
  end

  test "identity provider without password, invitable false", %{user: user} do
    Config.persist([sentinel: [invitable: false]])

    assert {:error, [password: {"A password is required to login", []}]} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      info: %Auth.Info{email: user.email},
      credentials: %Auth.Credentials{
        other: %{
          password: nil
        }
      },
      uid: user.email
    })
  end

  test "create new user, identity provider without password, invitable true" do
    Config.persist([sentinel: [invitable: true]])
    user = Factory.build(:user)

    assert {:ok, %{user: _user = %Sentinel.User{}, confirmation_token: _confirmation_token}} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      info: %Auth.Info{email: user.email},
      credentials: %Auth.Credentials{
        other: %{
          password: nil
        }
      },
      uid: user.email
    })
  end

  test "identity provider without email", %{auth: auth} do
    assert {:error, [email: {"An email is required to login", []}]} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: nil
    })
  end

  test "identity provider with password, unknown user", %{auth: auth} do
    assert {:error, [base: {"Unknown email or password", []}]} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: "nonexistant@example.com"
    })
  end

  test "identity provider with email and pass, user exists, auth exists, is successful", %{user: user, auth: auth} do
    assert {:ok, _user = %Sentinel.User{}} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: user.email
    })
  end

  test "identity provider with password and confirmation, user exists, auth DOESN'T, errors out" do
    user = Factory.insert(:user)

    assert {:error, [base: {"Unknown email or password", []}]} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: "password",
          password_confirmation: "password"
        }
      },
      uid: user.email
    })
  end

  test "identity provider with password and confirmation, user DOESN'T exist, auth DOESN'T, creates new user & auth" do
    assert {:ok,
      %{
        user: _user,
        confirmation_token: _confirmation_token
      }
    } = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      info: %Ueberauth.Auth.Info{
        email: "test@example.com",
      },
      credentials: %Auth.Credentials{
        other: %{
          password: "password",
          password_confirmation: "password"
        }
      },
      uid: "new_email@example.com"
    })
  end

  test "authenticate a confirmed user", %{confirmed_user: user, confirmed_auth: auth} do
    assert {:ok, _user = %Sentinel.User{}} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: user.email
    })
  end

  test "authenticate a confirmed user - case insensitive" do
    user = Factory.insert(:user, confirmed_at: Ecto.DateTime.utc)
    auth = Factory.insert(:ueberauth, user: user)

    assert {:ok, _user = %Sentinel.User{}} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: String.upcase(user.email)
    })
  end

  test "authenticate an unconfirmed user - confirmable default/optional", %{user: user, auth: auth} do
    Config.persist([sentinel: [confirmable: :optional]])

    assert {:ok, _user = %Sentinel.User{}} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: user.email
    })
  end

  test "authenticate an unconfirmed user - confirmable false", %{user: user, auth: auth} do
    Config.persist([sentinel: [confirmable: :false]])

    assert {:ok, _user = %Sentinel.User{}} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: user.email
    })

    Config.persist([sentinel: [confirmable: :optional]])
  end

  test "authenticate an unconfirmed user - confirmable required", %{user: user, auth: auth} do
    Config.persist([sentinel: [confirmable: :required]])

    assert {:error, _} = Ueberauthenticator.ueberauthenticate(%Auth{
      provider: :identity,
      credentials: %Auth.Credentials{
        other: %{
          password: auth.plain_text_password
        }
      },
      uid: user.email
    })

    Config.persist([sentinel: [confirmable: :optional]])
  end
end
