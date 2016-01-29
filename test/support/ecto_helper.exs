defmodule Sentinel.TestRepo do
  use Ecto.Repo, otp_app: :sentinel
end
alias Sentinel.TestRepo

defmodule Sentinel.Case do
  use ExUnit.CaseTemplate
  setup_all do
    Ecto.Adapters.SQL.begin_test_transaction(TestRepo, [])
    on_exit fn -> Ecto.Adapters.SQL.rollback_test_transaction(TestRepo, []) end
    :ok
  end
  setup do
    Ecto.Adapters.SQL.restart_test_transaction(TestRepo, [])
    :ok
  end
end

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

# Load up the repository, start it, and run migrations
Ecto.Storage.down(TestRepo)
:ok = Ecto.Storage.up(TestRepo)
{:ok, _pid} = TestRepo.start_link
:ok = Ecto.Migrator.up(TestRepo, 0, UsersMigration, log: false)
:ok = Ecto.Migrator.up(TestRepo, 1, GuardianDbMigration, log: false)

defmodule Sentinel.User do
  use Ecto.Model

  schema "users" do
    field  :email,                       :string
    field  :username,                    :string
    field  :role,                        :string
    field  :hashed_password,             :string
    field  :hashed_confirmation_token,   :string
    field  :confirmed_at,                Ecto.DateTime
    field  :hashed_password_reset_token, :string
    field  :unconfirmed_email,           :string
  end

  @required_fields ~w()
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def permissions(role \\ "user") do
    permissions_env = Application.get_env(:sentinel, :permissions)
  end
end
