defmodule Sentinel.Ueberauthenticator do
  @moduledoc """
  Common authentication logic using the ueberauth underlying layer
  """
  alias Ueberauth.Auth
  alias Sentinel.Authenticator
  alias Sentinel.Changeset.Registrator
  alias Sentinel.Changeset.Confirmator
  alias Sentinel.Config
  alias Sentinel.Ueberauth

  @unknown_error {:error, [base: {"Unknown email or password", []}]}

  def ueberauthenticate(auth = %Auth{provider: :identity, credentials: %Auth.Credentials{other: %{password: password}}}) when is_nil(password) or password == "" do
    if invitable?() do
      create_user_and_auth(auth)
    else
      {:error, [password: {"A password is required to login", []}]}
    end
  end
  def ueberauthenticate(%Auth{provider: :identity, uid: email}) when is_nil(email) or email == "" do
    {:error, [email: {"An email is required to login", []}]}
  end
  def ueberauthenticate(%Auth{provider: :identity, uid: uid, credentials: %Auth.Credentials{other: %{password: password, password_confirmation: password_confirmation}}}) when is_nil(password_confirmation) or password_confirmation == "" do
    Config.user_model
    |> Config.repo.get_by(email: String.downcase(uid))
    |> find_auth_and_authenticate(password)
  end
  def ueberauthenticate(%Auth{provider: :identity, uid: uid, credentials: %Auth.Credentials{other: %{password: password, password_confirmation: password_confirmation}}} = auth) when password == password_confirmation do
    user =
      Config.user_model
      |> Config.repo.get_by(email: String.downcase(uid))

    if is_nil(user) do
      create_user_and_auth(auth)
    else
      db_auth = Config.repo.get_by(Ueberauth, provider: "identity", user_id: user.id)
      authenticate(user, db_auth, password)
    end
  end
  def ueberauthenticate(%Auth{provider: :identity, uid: uid, credentials: %Auth.Credentials{other: %{password: password, password_confirmation: password}}}) do
    Config.user_model
    |> Config.repo.get_by(email: String.downcase(uid))
    |> find_auth_and_authenticate(password)
  end
  def ueberauthenticate(%Auth{provider: :identity, uid: _uid, credentials: %Auth.Credentials{other: %{password: _password, password_confirmation: _password_confirmation}}}) do
    {:error, [%{password: "Password must match password confirmation"}]}
  end
  def ueberauthenticate(%Auth{provider: :identity, uid: uid, credentials: %Auth.Credentials{other: %{password: password}}}) do
    Config.user_model
    |> Config.repo.get_by(email: String.downcase(uid))
    |> find_auth_and_authenticate(password)
  end
  def ueberauthenticate(%Auth{uid: uid} = auth_params) do
    auth =
      Sentinel.Ueberauth
      |> Config.repo.get_by(uid: uid)
      |> Config.repo.preload([:user])

    if is_nil(auth) do
      user = Config.repo.get_by(Config.user_model, email: auth_params.info.email)
      if is_nil(user) do
        create_user_and_auth(auth_params)
      else
        updated_auth = auth_params |> Map.put(:provider, Atom.to_string(auth_params.provider))
        auth_changeset =
          %Sentinel.Ueberauth{uid: user.id, user_id: user.id}
          |> Sentinel.Ueberauth.changeset(Map.from_struct(updated_auth))

        case Config.repo.insert(auth_changeset) do
          {:ok, _auth} -> {:ok, user}
          {:error, error} -> {:error, error}
        end
      end
    else
      {:ok, auth.user}
    end
  end

  defp find_auth_and_authenticate(user, password) do
    if is_nil(user) do
      @unknown_error
    else
      db_auth = Config.repo.get_by(Ueberauth, provider: "identity", user_id: user.id)
      authenticate(user, db_auth, password)
    end
  end

  defp authenticate(nil, _auth, _password) do
    @unknown_error
  end
  defp authenticate(_user, nil, _password) do
    @unknown_error
  end
  defp authenticate(user, auth, password) do
    auth
    |> Map.put(:user, user)
    |> Authenticator.authenticate(password)
  end

  defp create_user_and_auth(auth) do
    if Config.registerable?() do
      updated_auth = auth |> Map.put(:provider, Atom.to_string(auth.provider))

      Config.repo.transaction(fn ->
        {confirmation_token, changeset} =
          updated_auth.info
          |> Map.from_struct
          |> Registrator.changeset(updated_auth.extra.raw_info)
          |> Confirmator.confirmation_needed_changeset

        user =
          case Config.repo.insert(changeset) do
            {:ok, user} -> user
            _ -> Config.repo.rollback(changeset.errors)
          end

        auth_changeset =
          %Sentinel.Ueberauth{uid: user.id, user_id: user.id}
          |> Sentinel.Ueberauth.changeset(Map.from_struct(updated_auth))

        case Config.repo.insert(auth_changeset) do
          {:ok, _auth} -> nil
          _ -> Config.repo.rollback(changeset.errors)
        end

        %{user: user, confirmation_token: confirmation_token}
      end)
    else
      {:error, [base: {"New user registration is not permitted", []}]}
    end
  end

  defp invitable? do
    Config.invitable
  end
end
