defmodule Sentinel.Ueberauth do
  @moduledoc """
  Models the database backed ueberauth data, which allows authentication using
  a variety of services
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Sentinel.Config
  alias Sentinel.Changeset.HashPassword

  if Application.get_env(:sentinel, :uuid_primary_keys, false) do
    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
  end

  schema "ueberauths" do
    field :provider, :string
    field :uid, :string
    field :expires_at, Ecto.DateTime
    field :hashed_password, :string
    field :hashed_password_reset_token, :string
    belongs_to :user, Config.user_model

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{})
  def changeset(struct, %{provider: :identity} = params) do
    updated_params = coerce_provider_to_string(params)
    identity_changeset(struct, updated_params)
  end
  def changeset(struct, %{provider: "identity"} = params) do
    identity_changeset(struct, params)
  end
  def changeset(struct, params) do
    updated_params = coerce_provider_to_string(params)

    struct
    |> cast(updated_params, [:provider, :uid, :expires_at, :user_id])
    |> validate_required([:provider, :uid, :user_id])
  end

  defp identity_changeset(struct, params) do
    struct
    |> cast(params, [:provider, :uid, :expires_at, :hashed_password, :hashed_password_reset_token, :user_id])
    |> validate_required([:provider, :uid, :user_id])
    |> assoc_constraint(:user)
    |> HashPassword.changeset(params)
  end

  defp coerce_provider_to_string(%{provider: provider} = params) when is_atom(provider) do
    Map.put(params, :provider, Atom.to_string(params.provider))
  end
  defp coerce_provider_to_string(params) do
    params
  end
end
