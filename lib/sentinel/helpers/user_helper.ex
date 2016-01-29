defmodule Sentinel.UserHelper do
  import Ecto.Query, only: [from: 2]
  alias Sentinel.Util

  def model do
    Application.get_env(:sentinel, :user_model)
  end

  def find_by_email(email) do
    query = from u in model, where: u.email == ^email
    Util.repo.one query
  end

  def find_by_username(username) do
    query = from u in model, where: u.username == ^username
    Util.repo.one query
  end

  def validator(changeset) do
    apply_validator(Application.get_env(:sentinel, :user_model_validator),
    changeset)
  end
  defp apply_validator(nil, changeset), do: changeset
  defp apply_validator({mod, fun}, changeset), do: apply(mod, fun, [changeset])
  defp apply_validator(validator, changeset) do
    validator.(changeset)
  end
end
