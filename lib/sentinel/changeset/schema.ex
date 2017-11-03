defmodule Sentinel.Changeset.Schema do
  @moduledoc """
  Module holding the changeset function responsible for downcasing
  & validating emails
  """
  import Ecto.Changeset
  @email_regex ~r/\A[^@\s]+@[^@\s]+\z/

  def changeset(changeset) do
    changeset
    |> validate_required([:email])
    |> downcase_email
    |> validate_email_against_regex
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

  defp validate_email_against_regex(changeset) do
    changeset
    |> get_change(:email)
    |> match_email(changeset)
  end

  defp match_email(nil, changeset) do
    changeset
  end
  defp match_email(email, changeset) do
    if String.match?(email, @email_regex) do
      changeset
    else
      add_error(changeset, :email, "not valid")
    end
  end
end
