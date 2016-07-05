defmodule Sentinel.UserHelper do
  alias Sentinel.Util

  def model do
    Application.get_env(:sentinel, :user_model)
  end

  def find_by_email(email) do
    Util.repo.get_by(Sentinel.UserHelper.model, email: email)
  end

  def find_by_username(username) do
    Util.repo.get_by(Sentinel.UserHelper.model, username: username)
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
