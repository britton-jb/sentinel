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
    field :failed_attempts, :integer
    field :locked_at, Ecto.DateTime
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
    |> cast(updated_params, [:provider, :uid, :expires_at, :user_id, :locked_at])
    |> validate_required([:provider, :uid, :user_id])
    |> validates_provider_doesnt_already_exist_for_user
    |> assoc_constraint(:user)
  end

  @spec increment_failed_attempts(%Sentinel.Ueberauth{}) :: %Sentinel.Ueberauth{}
  def increment_failed_attempts(auth) do
    {:ok, updated_auth} =
      auth
      |> Sentinel.Ueberauth.changeset(%{failed_attempts: (auth.failed_attempts || 0) + 1})
      |> Sentinel.Config.repo.update()
  end

  @spec lock(%Sentinel.Ueberauth{}) :: %Sentinel.Ueberauth{}
  def lock(auth) do
    {:ok, updated_auth} =
      auth
      |> Sentinel.Ueberauth.changeset(%{
        failed_attempts: 5,
        locked_at: Ecto.DateTime.utc(),
      }) |> Sentinel.Config.repo.update()
  end

  @spec unlock(%Sentinel.Ueberauth{}) :: %Sentinel.Ueberauth{}
  def unlock(auth) do
    {:ok, updated_auth} =
      auth
      |> Sentinel.Ueberauth.changeset(%{
        failed_attempts: 0,
        locked_at: nil,
      }) |> Sentinel.Config.repo.update()
  end

  defp identity_changeset(struct, params) do
    struct
    |> cast(params, [:provider, :uid, :expires_at, :hashed_password, :hashed_password_reset_token, :user_id, :locked_at])
    |> validate_required([:provider, :uid, :user_id])
    |> assoc_constraint(:user)
    |> validates_provider_doesnt_already_exist_for_user
    |> HashPassword.changeset(params)
  end

  defp coerce_provider_to_string(%{provider: provider} = params) when is_atom(provider) do
    Map.put(params, :provider, Atom.to_string(params.provider))
  end
  defp coerce_provider_to_string(params) do
    params
  end

  defp validates_provider_doesnt_already_exist_for_user(changeset) do
    with provider_atom when not is_nil(provider_atom) <- get_change(changeset, :provider),
         user_id       when not is_nil(user_id)       <- get_change(changeset, :user_id),
         ueberauth     when not is_nil(ueberauth)     <- Sentinel.Config.repo.get_by(Sentinel.Config.user_model, provider: provider_atom, user_id: user_id) do
      add_error(changeset, :provider, "already exists for this user")
    else
      _ -> changeset
    end
  end
end
