defmodule Sentinel.Changeset.Schema do
  @moduledoc """
  Module holding the changeset function responsible for downcasing
  & validating emails
  """
  import Ecto.Changeset

  def changeset(changeset) do
    changeset
    |> validate_required([:email])
    |> downcase_email
    |> unique_constraint(:email)
  end

  defp downcase_email(changeset) do
    email = get_change(changeset, :email)
    if is_nil(email) do
      changeset
    else
      put_change(changeset, :email, String.downcase(email))
    end
  end
end
