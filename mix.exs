defmodule Sentinel.Mixfile do
  use Mix.Project

  @version "3.0.0-rc1"
  @source_url "https://github.com/britton-jb/sentinel"

  def project do
    [app: :sentinel,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix] ++ Mix.compilers,
      package: package(),
      description: description(),
      source_url: @source_url,
      aliases: aliases(),
      deps: deps()]
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
      {:guardian, "~> 1.0-beta", override: true},
      {:guardian_db, github: "ueberauth/guardian_db", optional: true},
      {:secure_random, "~> 0.2"},
      {:bamboo, "~> 0.8"},
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 0.12"},

      {:cowboy, "~> 1.0"},
      {:phoenix, "~> 1.1"},
      {:phoenix_html, "~> 2.2"},
      {:phoenix_ecto, "~> 3.1"},
      {:ecto, "~> 2.1"},
      {:postgrex, ">= 0.11.1", override: true},

      {:ueberauth, "~> 0.4"},
      {:ueberauth_identity, "~> 0.2"},

      # DEV
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, github: "jeremyjh/dialyxir", only: [:dev], runtime: false},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:ex_guard, "~> 1.3", only: :dev},
      # TESTING
      {:mock, "~> 0.1", only: :test},
      {:ex_machina, "~> 2.0", only: :test},
      {:ex_spec, "~> 2.0", only: :test},
    ]
  end

  defp aliases do
    [
      "test": ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"],
      "static_analysis": ["credo", "dialyzer"],
      "precommit": ["test", "static_analysis"]
    ]
  end
end
