defmodule Sentinel.Confirm do
  @moduledoc """
  Handles the common confirmation logic
  """
  alias Sentinel.Changeset.Confirmator
  alias Sentinel.Config

  def send_confirmation_instructions(params) do
    user = Config.repo.get_by(Config.user_model, email: params["email"])
    if user do
      ueberauth = Config.repo.get_by(Sentinel.Ueberauth, provider: "identity", user_id: user.id)

      if ueberauth do
        {confirmation_token, changeset} =
          ueberauth
          |> Registrator.changeset
          |> Confirmator.confirmation_needed_changeset

        Config.repo.insert(changeset)

        user
        |> Mailer.send_welcome_email(confirmation_token)
        |> Mailer.managed_deliver
      end
    end
  end

  def do_confirm(params) do
    Config.user_model
    |> Config.repo.get_by(email: params["email"])
    |> Config.user_model.changeset(params)
    |> Confirmator.confirmation_changeset
    |> Config.repo.update
  end
end
