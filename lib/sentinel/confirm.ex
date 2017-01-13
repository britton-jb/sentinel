defmodule Sentinel.Confirm do
  @moduledoc """
  Handles the common confirmation logic
  """
  alias Sentinel.Changeset.Confirmator
  alias Sentinel.Config

  def do_confirm(params) do
    Config.user_model
    |> Config.repo.get_by(email: params["email"])
    |> Config.user_model.changeset(params)
    |> Confirmator.confirmation_changeset
    |> Config.repo.update
  end
end
