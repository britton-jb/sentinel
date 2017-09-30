defmodule Sentinel.Update do
  @moduledoc """
  Handles abstracted update logic from controllers
  """

  alias Sentinel.{Changeset.AccountUpdater, Changeset.PasswordResetter, Config, Mailer, Util}

  def update(current_user, %{"password" => password} = params) do
    Config.repo.transaction(fn ->
      {updated_user, confirmation_token} = update_user(current_user, params)

      auth = Config.repo.get_by(Sentinel.Ueberauth, user_id: current_user.id, provider: "identity")
      auth =
        if is_nil(auth) do
          auth_struct = %Ueberauth.Auth{
            provider: "identity",
            credentials: %Ueberauth.Auth.Credentials{
              other: %{
                password: password
              }
            },
            uid: current_user.email
          }

          %Sentinel.Ueberauth{uid: current_user.id, user_id: current_user.id}
          |> Sentinel.Ueberauth.changeset(Map.from_struct(auth_struct))
          |> Config.repo.insert!
        else
          auth
        end

      {password_reset_token, password_changeset} = auth |> PasswordResetter.create_changeset
      updated_auth =
        case Config.repo.update(password_changeset) do
          {:ok, updated_auth} -> updated_auth
          _ -> Config.repo.rollback(password_changeset)
        end

      password_reset_params = Sentinel.Util.params_to_ueberauth_auth_struct(params, password_reset_token)

      auth_changeset =
      updated_auth
      |> PasswordResetter.reset_changeset(password_reset_params)

      final_auth =
        case Config.repo.update(auth_changeset) do
          {:ok, final_auth} -> final_auth
          _ -> Config.repo.rollback(auth_changeset)
        end

      %{user: updated_user, auth: final_auth, confirmation_token: confirmation_token}
    end)
  end
  def update(current_user, params) do
    Config.repo.transaction(fn ->
      {updated_user, confirmation_token} = update_user(current_user, params)

      %{user: updated_user, auth: nil, confirmation_token: confirmation_token}
    end)
  end

  defp update_user(current_user, params) do
    {confirmation_token, user_changeset} = current_user |> AccountUpdater.changeset(params)

    case Config.repo.update(user_changeset) do
      {:ok, updated_user} -> {updated_user, confirmation_token}
      _ -> Config.repo.rollback(user_changeset)
    end
  end

  def update_password(nil, params) do
    password_reset_params = Util.params_to_ueberauth_auth_struct(params)

    %Sentinel.Ueberauth{}
    |> PasswordResetter.reset_changeset(password_reset_params)
    |> Config.repo.update
  end
  def update_password(user_id, params) do
    password_reset_params = Util.params_to_ueberauth_auth_struct(params)

    Sentinel.Ueberauth
    |> Config.repo.get_by!(user_id: user_id, provider: "identity")
    |> PasswordResetter.reset_changeset(password_reset_params)
    |> Config.repo.update
  end

  def maybe_send_new_email_address_confirmation_email(user, confirmation_token \\ nil)
  def maybe_send_new_email_address_confirmation_email(_user, nil) do
  end
  def maybe_send_new_email_address_confirmation_email(user, confirmation_token) do
    user |> Mailer.send_new_email_address_email(confirmation_token)
  end
end
