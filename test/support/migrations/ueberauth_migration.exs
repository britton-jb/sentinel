defmodule UeberauthMigration do
  use Ecto.Migration

  def change do
    create table(:ueberauths) do
      add :provider, :string, null: false
      add :uid, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # identity
      add :hashed_password, :text
      add :hashed_password_reset_token, :text
      add :failed_attempts, :integer, default: 0
      add :locked_at, :utc_datetime
      add :unlock_token, :string

      # ueberauth
      add :credentials, :map

      timestamps()
    end

    create index(:ueberauths, [:user_id])
    create index(:ueberauths, [:uid])
    create index(:ueberauths, [:user_id, :provider], unique: true)
    create constraint(
      :ueberauths,
      "ueberauths_credentials_properly_structured",
      check: "credentials = null OR (credentials::jsonb ?& array['token', 'refresh_token', 'token_type', 'secret', 'expires', 'expires_at', 'scopes'])"
    )
  end
end
