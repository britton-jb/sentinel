defmodule Sentinel.TestValidator do
  import Ecto.Changeset

  def custom_changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [:my_attr])
    |> validate_required([:my_attr])
    |> validate_inclusion(:my_attr, ["foo", "bar"])
  end
end
