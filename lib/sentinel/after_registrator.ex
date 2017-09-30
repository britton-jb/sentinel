defmodule Sentinel.AfterRegistrator do
  @moduledoc """
  Handles the email sending logic after a new user is registered to the platform
  """
  alias Sentinel.{Config, Mailer, Changeset.PasswordResetter}

  def confirmable_and_invitable(user, confirmation_token) do
    case {confirmable?(), invitable?()} do # NOTE move this from a case to private methods?
      {false, false} -> # not confirmable or invitable
        {:ok, user}

      {_confirmable, :true} ->
        ueberauth = Config.repo.get_by!(
          Sentinel.Ueberauth,
          user_id: user.id
        )

        if ueberauth.provider == "identity" && is_nil(ueberauth.hashed_password) do
          {password_reset_token, changeset} =
            ueberauth
            |> PasswordResetter.create_changeset
          Config.repo.update!(changeset)

          Mailer.send_invite_email(user, %{
            confirmation_token: confirmation_token,
            password_reset_token: password_reset_token
          })
        else
          Mailer.send_welcome_email(user, confirmation_token)
        end

        {:ok, user}

      {_required, _invitable} ->
        Mailer.send_welcome_email(user, confirmation_token)
        {:ok, user}
    end
  end

  defp confirmable? do
    case Config.confirmable do
      :required -> :required
      :false -> :false
      _ -> :optional
    end
  end

  defp invitable? do
    Config.invitable
  end
end
