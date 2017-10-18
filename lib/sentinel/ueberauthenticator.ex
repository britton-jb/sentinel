defmodule Sentinel.Ueberauthenticator do
  @moduledoc """
  Common authentication logic using the ueberauth underlying layer
  """
  alias Ueberauth.Auth
  alias Sentinel.{Authenticator, Changeset.Registrator, Changeset.Confirmator, Config, Ueberauth}

  @unknown_error {:error, [base: {"Unknown email or password", []}]}
  @locked_error {:error, [lockable: {"Your account is currently locked. Please follow the instructions we sent you by email to unlock it.", []}]}

  def ueberauthenticate(%Auth{provider: :identity, uid: email}) when is_nil(email) or email == "" do
    {:error, [email: {"can't be blank", []}]}
  end
  def ueberauthenticate(auth = %Auth{provider: :identity, credentials: %Auth.Credentials{other: %{password: password}}}) when is_nil(password) or password == "" do
    if invitable?() do
      create_user_and_auth(auth)
    else
      {:error, [password: {"A password is required to login", []}]}
    end
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
    string_uid = coerce_to_string(uid)

    updated_auth_params =
      auth_params
      |> Map.put(:provider, coerce_to_string(auth_params.provider))
      |> Map.put(:uid, string_uid)

    auth =
      Sentinel.Ueberauth
      |> Config.repo.get_by(uid: string_uid)
      |> Config.repo.preload([:user])

    if is_nil(auth) do
      user = Config.repo.get_by(Config.user_model, email: updated_auth_params.info.email)
      if is_nil(user) do
        create_user_and_auth(updated_auth_params, string_uid)
      else
        auth_changeset =
          %Sentinel.Ueberauth{uid: string_uid, user_id: user.id}
          |> Sentinel.Ueberauth.changeset(Map.from_struct(updated_auth_params))

        case Config.repo.insert(auth_changeset) do
          {:ok, _auth} -> {:ok, user}
          {:error, error} -> {:error, error}
        end
      end
    else
      auth_changeset = Sentinel.Ueberauth.changeset(auth, Map.from_struct(updated_auth_params))
      Config.repo.update(auth_changeset)
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
  defp authenticate(_user, %Ueberauth{locked_at: locked_at}, _password) when locked_at != nil do
    @locked_error
  end
  defp authenticate(user, auth, password) do
    auth
    |> Map.put(:user, user)
    |> Authenticator.authenticate(password)
  end

  defp create_user_and_auth(auth, provided_uid \\ nil) do
    if Config.registerable?() || invitable?() do
      updated_auth = auth |> Map.put(:provider, coerce_to_string(auth.provider))

      Config.repo.transaction(fn ->
        {confirmation_token, user_changeset} =
          updated_auth.info
          |> Map.from_struct
          |> Registrator.changeset(updated_auth.extra.raw_info)
          |> Confirmator.confirmation_needed_changeset

        with {:ok, user} <- Config.repo.insert(user_changeset),
             uid = set_uid(provided_uid, user),
             updated_auth = Map.merge(Map.from_struct(updated_auth), %{uid: uid, user_id: user.id}),
             auth_changeset <- Sentinel.Ueberauth.changeset(%Sentinel.Ueberauth{}, updated_auth),
             {:ok, _auth} <- Config.repo.insert(auth_changeset) do
          %{user: user, confirmation_token: confirmation_token}
        else
          {:error, error_changeset} -> Config.repo.rollback(error_changeset.errors)
        end
      end)
    else
      {:error, [base: {"New user registration is not permitted", []}]}
    end
  end

  defp set_uid(nil, user), do: coerce_to_string(user.id)
  defp set_uid(provided_uid, _user), do: coerce_to_string(provided_uid)

  defp coerce_to_string(var) when is_bitstring(var), do: var
  defp coerce_to_string(var) when is_integer(var), do: Integer.to_string(var)
  defp coerce_to_string(var) when is_atom(var), do: Atom.to_string(var)

  defp invitable? do
    Config.invitable
  end
end
