defmodule Sentinel.Invited do
  @moduledoc """
  Handles the common invitation logic
  """
  alias Sentinel.Changeset.Confirmator
  alias Sentinel.Changeset.PasswordResetter
  alias Sentinel.Config
  alias Sentinel.Util

  def do_invited(%{"id" => id, "user" => user_params} = params) do
    handler(id, user_params)
  end
  def do_invited(%{"id" => id} = params) do
    handler(id, params)
  end

  defp handler(id, params) do
    user = Config.repo.get(Config.user_model, id)
    auth = Config.repo.get_by(Sentinel.Ueberauth, provider: "identity", user_id: user.id)

    auth_params = Util.params_to_ueberauth_auth_struct(params)
    auth_changeset = PasswordResetter.reset_changeset(auth, auth_params)
    user_changeset =
      user
      |> Config.user_model.changeset(%{confirmation_token: params["confirmation_token"]})
      |> Confirmator.confirmation_changeset

    case {Config.repo.update(auth_changeset), Config.repo.update(user_changeset)} do
      {{:ok, _auth}, {:ok, updated_user}} -> {:ok, updated_user}
      {{:error, _}, _} -> {:error, auth_changeset}
      {_, {:error, _}} -> {:error, user_changeset}
    end
  end
end
