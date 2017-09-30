ExUnit.start()
{:ok, _} = Application.ensure_all_started(:ex_machina)

Application.put_env(:phoenix, :filter_parameters, [])
Application.put_env(:phoenix, :format_encoders, [json: Poison])

Code.require_file "test/support/migrations/user_migration.exs"
Code.require_file "test/support/migrations/ueberauth_migration.exs"
Code.require_file "test/support/migrations/guardian_db_migration.exs"
Code.require_file "test/support/compile_time_assertions.exs"
Code.require_file "test/support/endpoint.exs"
Code.require_file "test/support/router.exs"
Code.require_file "test/support/unit_case.exs"
Code.require_file "test/support/conn_case.exs"
Code.require_file "test/support/mailer_helper.exs"
Code.require_file "test/support/factories.exs"

{:ok, _pid} = Sentinel.Endpoint.start_link
{:ok, _pid} = Sentinel.TestRepo.start_link
Mix.Task.run "ecto.create", ~w(-r Sentinel.TestRepo --quiet)
Ecto.Migrator.up(Sentinel.TestRepo, 0, UsersMigration, log: false)
Ecto.Migrator.up(Sentinel.TestRepo, 1, GuardianDbMigration, log: false)
Ecto.Migrator.up(Sentinel.TestRepo, 2, UeberauthMigration, log: false)
