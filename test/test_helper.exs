ExUnit.start()

Application.put_env(:phoenix, :filter_parameters, [])
Application.put_env(:phoenix, :format_encoders, [json: Poison])

Code.require_file "test/support/migrations/migrations.exs"
Code.require_file "test/support/router_helper.exs"
Code.require_file "test/support/forge.exs"

defmodule Sentinel.TestCase do
  use ExUnit.CaseTemplate
  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Sentinel.TestRepo)

    Ecto.Adapters.SQL.Sandbox.mode(Sentinel.TestRepo, {:shared, self()})
  end
end

{:ok, _pid} = Sentinel.TestRepo.start_link
Ecto.Migrator.up(Sentinel.TestRepo, 0, UsersMigration, log: false)
Ecto.Migrator.up(Sentinel.TestRepo, 1, GuardianDbMigration, log: false)
