defmodule Sentinel.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "virtual_session_table" do
    field :email, :string
    field :password, :string
  end

  @required_fields ~w(email password)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
  end
end
