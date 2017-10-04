defmodule Mix.Tasks.Sentinel.Install do
  @moduledoc """
  Used to initially setup and configure sentinel
  """
  @shortdoc "Used to initially setup and configure sentinel"

  use Mix.Task

  def run(args) do
    IO.puts "Creating migrations"
    create_migrations(args)

    IO.puts "You should go in and ensure your application is configured correctly"
  end

  defp create_migrations(args) do
    legacy = !Kernel.function_exported?(Mix.Phoenix, :web_path, 1)
    Mix.Tasks.Ecto.run(["-r", "#{Sentinel.Config.repo()}"])
    migrations_path = Mix.Ecto.migrations_path(Sentinel.Config.repo())

    if File.exists?(migrations_path) do
      migrations = Path.wildcard("#{migrations_path}/*.exs")

      create_user_migration(args, legacy)

      migrations
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "guardian")
      end) |> create_guardian_token_migration()

      migrations
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "ueberauth")
      end) |> create_ueberauth_migration()
    else
      create_user_migration(args, legacy)
      create_guardian_token_migration()
      create_ueberauth_migration()
    end
  end

  defp create_user_migration(args, legacy) do
    if legacy do
      Mix.Tasks.Phoenix.Gen.Model.run(args ++ [
        "email:string",
        "hashed_confirmation_token:text",
        "confirmed_at:datetime",
        "unconfirmed_email:string"
      ])
    else
      Mix.Tasks.Phx.Gen.Schema.run(args ++ [
        "email:string",
        "hashed_confirmation_token:text",
        "confirmed_at:utc_datetime",
        "unconfirmed_email:string"
      ])
    end

    IO.puts "Make sure to include `Sentinel.Changeset.Schema.changeset/1` in your changeset"
    IO.puts "This ensures emails are required and downcased properly before insertion.\n"
    IO.puts "Also make sure to remove the unconfirmed_email, confirmed_at, and hashed_confirmation_token"
    IO.puts "from the validate_required/2 list."
    IO.puts "Finally, add `create index(:users, [:email], unique: true)` to the users migration."
    Process.sleep(1001)
  end

  defp create_guardian_token_migration do
    generate_token_migration()
  end
  defp create_guardian_token_migration(nil) do
    generate_token_migration()
  end
  defp create_guardian_token_migration(_migration) do
    IO.puts "A guardian token migration appears to already exist"
  end

  defp generate_token_migration do
    Mix.Tasks.Ecto.Gen.Migration.run(["AddGuardianDbTokens"])

    Process.sleep(1001)

    migrations_path = Mix.Ecto.migrations_path(Sentinel.Config.repo())

    token_migration_path =
      "#{migrations_path}/*.exs"
      |> Path.wildcard
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "add_guardian_db_tokens")
      end)

    migration_content =
      token_migration_path
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(0..2)

    new_content =
      :sentinel
      |> Application.app_dir("priv/templates/migrations/guardian_db_migration_template.ex")
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(3..100)

    token_migration_path
    |> File.write!(migration_content ++ new_content)
  end

  defp create_ueberauth_migration do
    generate_ueberauth()
  end
  defp create_ueberauth_migration(nil) do
    generate_ueberauth()
  end
  defp create_ueberauth_migration(_migration) do
    IO.puts "An ueberuath migration appears to already exist"
  end

  defp generate_ueberauth do
    Mix.Tasks.Ecto.Gen.Migration.run(["AddUeberauth"])

    Process.sleep(1001)

    migrations_path = Mix.Ecto.migrations_path(Sentinel.Config.repo())

    migration_path =
      "#{migrations_path}/*.exs"
      |> Path.wildcard
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "add_ueberauth")
      end)

    migration_content =
      migration_path
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(0..2)

    new_content =
      :sentinel
      |> Application.app_dir("priv/templates/migrations/ueberauth_migration_template.ex")
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(3..100)

    migration_path
    |> File.write!(migration_content ++ new_content)

    IO.puts "If your user table isn't `users` make sure to modify your Ueberauth migration to the correct table name"
  end
end
