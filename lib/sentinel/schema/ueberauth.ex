defmodule Sentinel.Ueberauth do
  @moduledoc """
  Models the database backed ueberauth data, which allows authentication using
  a variety of services
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Sentinel.{Config, Changeset.HashPassword}

  if Application.get_env(:sentinel, :uuid_primary_keys, false) do
    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
  end

  schema "ueberauths" do
    # both
    field :provider, :string, null: false
    field :uid, :string, null: false
    belongs_to :user, Config.user_model

    # other
    embeds_one :credentials, Credentials, on_replace: :update do
      field :token, :string
      field :refresh_token, :string
      field :token_type, :string
      field :secret, :string
      field :expires, :boolean
      field :expires_at, :utc_datetime
      field :scopes, {:array, :string}
    end

    # identity
    field :hashed_password, :string
    field :hashed_password_reset_token, :string
    field :failed_attempts, :integer
    field :locked_at, :utc_datetime
    field :unlock_token, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{})
  def changeset(%{provider: initial_provider} = struct, %{provider: params_provider} = params) when not (initial_provider == :identity or initial_provider == "identity") and not (params_provider == :identity or params_provider == "identity" or params_provider == nil) do
    updated_params = coerce_provider_to_string(params)

    struct
    |> cast(updated_params, [:provider, :uid, :user_id])
    |> validate_required([:provider, :uid, :user_id])
    |> validates_provider_doesnt_already_exist_for_user
    |> assoc_constraint(:user)
    |> cast_embed(:credentials, with: &credentials_changeset/2)
  end
  def changeset(struct, params) do
    updated_params = coerce_provider_to_string(params)
    identity_changeset(struct, updated_params)
  end

  defp credentials_changeset(struct, params) do
    updated_params =
      case params do
        %{credentials: credentials} -> credentials
        %Ueberauth.Auth.Credentials{} -> Map.from_struct(params)
        _ -> %{}
      end

    if updated_params == %{} do
      %Ecto.Changeset{}
    else
      struct
      |> cast(updated_params, [:token, :refresh_token, :token_type, :secret, :expires, :expires_at, :scopes])
      |> validate_required([:token, :token_type])
    end
  end

  @spec increment_failed_attempts(%Sentinel.Ueberauth{}) :: {:ok, %Sentinel.Ueberauth{}} | {:error, Ecto.Changeset.t}
  def increment_failed_attempts(auth) do
    {:ok, _updated_auth} =
      auth
      |> Sentinel.Ueberauth.changeset(%{failed_attempts: (auth.failed_attempts || 0) + 1})
      |> Config.repo.update()
  end

  @spec lock(%Sentinel.Ueberauth{}) :: {:ok, %Sentinel.Ueberauth{}}
  def lock(auth) do
    {:ok, updated_auth} =
      auth
      |> Sentinel.Ueberauth.changeset(%{
        failed_attempts: 5,
        locked_at: DateTime.utc_now(),
        unlock_token: SecureRandom.urlsafe_base64()
      }) |> Config.repo.update()

    preloaded_auth = Config.repo.preload(updated_auth, [:user])
    Sentinel.Mailer.send_locked_account_email(preloaded_auth.user, preloaded_auth.unlock_token)

    {:ok, preloaded_auth}
  end

  @spec unlock(String.t()) :: {:ok, %Sentinel.Ueberauth{}} | {:error, Ecto.Changeset.t}
  def unlock(unlock_token) do
    Sentinel.Ueberauth
    |> Config.repo.get_by(unlock_token: unlock_token)
    |> Sentinel.Ueberauth.changeset(%{
        failed_attempts: 0,
        locked_at: nil,
        unlock_token: nil,
      }) |> Config.repo.update()
  end

  defp identity_changeset(struct, params) do
    struct
    |> cast(params, [:provider, :uid, :hashed_password, :hashed_password_reset_token, :user_id, :failed_attempts, :locked_at, :unlock_token])
    |> validate_required([:provider, :uid, :user_id])
    |> assoc_constraint(:user)
    |> validates_provider_doesnt_already_exist_for_user
    |> Sentinel.PasswordValidator.changeset(params)
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
         ueberauth     when not is_nil(ueberauth)     <- Config.repo.get_by(Sentinel.Ueberauth, provider: provider_atom, user_id: user_id) do
      add_error(changeset, :provider, "already exists for this user")
    else
      _ -> changeset
    end
  end
end
