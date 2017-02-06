defmodule Sentinel.Mixfile do
  use Mix.Project

  @version "2.0.0"
  @source_url "https://github.com/britton-jb/sentinel"

  def project do
    [app: :sentinel,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix] ++ Mix.compilers,
      package: package,
      description: description,
      source_url: @source_url,
      aliases: aliases,
      deps: deps]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: applications(:all) ++ [:ex_machina]
  defp applications(_all),  do: [
    :bamboo,
    :comeonin,
    :ecto,
    :guardian,
    :logger,
    :phoenix,
    :phoenix_html,
    :postgrex,
    :ueberauth,
    :ueberauth_identity,
  ]

  defp package do
    [
      maintainers: ["Britton Broderick"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url,
        "Phoenix" => "https://github.com/phoenixframework/phoenix"}
    ]
  end

  defp description do
    """
    Adds helpful extras to Guardian like default mailer support, as well
    as out of the box controllers and routes
    """
  end

  defp deps do
    [
      {:guardian, "~> 0.14.2"},
      {:guardian_db, "~> 0.8.0", optional: true},
      {:secure_random, "~> 0.2"},
      {:bamboo, "~> 0.7"},
      {:comeonin, "~> 2.0.0"},

      {:cowboy, "~> 1.0.0"},
      {:phoenix, "~> 1.1"},
      {:phoenix_html, "~> 2.2"},
      {:phoenix_ecto, "~> 3.0"},
      {:ecto, "~> 2.1", override: true},
      {:postgrex, ">= 0.11.1"},
      {:jose, "~> 1.4"},

      {:ueberauth, "~> 0.4"},
      {:ueberauth_identity, "~> 0.2"},

      # DEV
      {:credo, "~> 0.5", only: [:dev, :test]},
      # TESTING
      {:mock, "~> 0.1", only: :test},
      {:ex_machina, "~> 1.0", only: :test},
    ]
  end

  defp aliases do
    [
      "test": ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
