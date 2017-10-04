defmodule UeberauthMigration do
  use Ecto.Migration

  def change do
    create table(:ueberauths) do
      add :provider, :string
      add :uid, :string
      add :expires_at, :utc_datetime
      add :hashed_password, :text
      add :hashed_password_reset_token, :text
      add :user_id, references(:users, on_delete: :delete_all)
      add :failed_attempts, :integer, default: 0
      add :locked_at, :utc_datetime
      add :unlock_token, :string
      timestamps()
    end

    create index(:ueberauths, [:user_id])
    create index(:ueberauths, [:uid])
  end
end
