defmodule UsersMigration do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email,    :text
      add :username, :text
      add :role, :text
      add :hashed_password, :text
      add :hashed_confirmation_token, :text
      add :confirmed_at, :datetime
      add :hashed_password_reset_token, :text
      add :unconfirmed_email,    :text
    end

    create index(:users, [:email], unique: true)
    create index(:users, [:username], unique: true)
  end
end

defmodule GuardianDbMigration do
  use Ecto.Migration

  def up do
    create table(:guardian_tokens, primary_key: false) do
      add :jti, :string, primary_key: true
      add :typ, :string
      add :aud, :string
      add :iss, :string
      add :sub, :string
      add :exp, :bigint
      add :jwt, :text
      add :claims, :map
      timestamps
    end
  end

  def down do
    drop table(:guardian_tokens)
  end
end
