defmodule Mix.Tasks.Sentinel.Install do
  @moduledoc """
  Used to initially setup and configure sentinel
  """
  @shortdoc "Used to initially setup and configure sentinel"

  use Mix.Task

  def run(_) do
    IO.puts "Creating migrations"
    create_migrations()

    IO.puts "You should go in and ensure your application is configured correctly"
  end

  defp create_migrations do
    if File.exists?("priv/repo/migrations") do
      migrations = Path.wildcard("priv/repo/migrations/*.exs")

      migrations
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "create_user")
      end) |> create_user_migration()

      migrations
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "guardian")
      end) |> create_guardian_token_migration()

      migrations
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "ueberauth")
      end) |> create_ueberauth_migration()
    else
      create_user_migration()
      create_guardian_token_migration()
      create_ueberauth_migration()
    end
  end

  defp create_user_migration do
    generate_user_migration()
  end
  defp create_user_migration(nil) do
    generate_user_migration()
  end
  defp create_user_migration(_) do
    IO.puts "A user creation migration appears to already exist"
  end

  defp generate_user_migration do
    Mix.Tasks.Phoenix.Gen.Model.run([
      "User",
      "users",
      "email:string",
      "hashed_confirmation_token:text",
      "confirmed_at:datetime",
      "unconfirmed_email:string"
    ])
    Process.sleep(1001)

    user_path = "web/models/user.ex"

    old_content =
      user_path
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(0..17)

    new_content =
      "deps/sentinel/lib/mix/templates/user_template.ex"
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(18..100)

    user_path
    |> File.write!(old_content ++ new_content)
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

    migration_path =
      "priv/repo/migrations/*.exs"
      |> Path.wildcard
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "guardian")
      end)

    migration_content =
      migration_path
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(0..2)

    new_content =
      "deps/sentinel/lib/mix/templates/guardian_db_migration_template.ex"
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(3..100)

    migration_path
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

    migration_path =
      "priv/repo/migrations/*.exs"
      |> Path.wildcard
      |> Enum.find(fn(migration) ->
        String.contains?(migration, "ueberauth")
      end)

    migration_content =
      migration_path
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(0..2)

    new_content =
      "deps/sentinel/lib/mix/templates/ueberauth_migration_template.ex"
      |> File.stream!
      |> Enum.map(fn(line) -> line end)
      |> Enum.slice(3..100)

    migration_path
    |> File.write!(migration_content ++ new_content)
  end
end
