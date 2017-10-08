defmodule Sentinel.Confirm do
  @moduledoc """
  Handles the common confirmation logic
  """
  alias Sentinel.{Changeset.Confirmator, Config, Mailer}

  def send_confirmation_instructions(%{"email" => email} = params) do
    user = Config.repo.get_by(Config.user_model, email: email)
    unless is_nil(user) do
      {confirmation_token, changeset} =
        params
        |> Sentinel.Changeset.Registrator.changeset
        |> Confirmator.confirmation_needed_changeset

      Config.repo.insert(changeset)

      user
      |> Mailer.send_welcome_email(confirmation_token)
      |> Mailer.managed_deliver
    end
  end
  def send_confirmation_instructions(_params) do
  end

  def do_confirm(%{"id" => id} = params) do
    Config.user_model
    |> Config.repo.get(id)
    |> Config.user_model.changeset(params)
    |> Confirmator.confirmation_changeset
    |> Config.repo.update
  end
  def do_confirm(_), do: {:error, :bad_request}
end
