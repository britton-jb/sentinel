defmodule Sentinel.Mixfile do
  use Mix.Project

  @version "1.0.1"
  @source_url "https://github.com/britton-jb/sentinel"

  def project do
    [app: :sentinel,
      version: @version,
      elixir: "~> 1.1",
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

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: applications(:all) ++ [:blacksmith]
  defp applications(_all),  do: [
    :logger,
    :comeonin,
    :ecto,
    :postgrex,
    :phoenix,
    :phoenix_html,
    :bamboo
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

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:guardian, "~> 0.12"},
      {:guardian_db, "~> 0.7", optional: true},
      {:secure_random, "~> 0.2"},
      {:comeonin, "~> 2.0"},
      {:bamboo, "~> 0.6"},
      #{:eiconv, github: "zotonic/eiconv"},

      {:cowboy, "~> 1.0.0"},
      {:phoenix, "~> 1.1"},
      {:phoenix_html, "~> 2.2"},
      {:phoenix_ecto, "~> 3.0"},
      {:ecto, "~> 2.0"},
      {:postgrex, ">= 0.11.1"},
      {:jose, "~> 1.4"},

      # DEV
      {:credo, "~> 0.4", only: [:dev, :test]},
      # TESTING
      {:mock, "~> 0.1", only: :test},
      {:blacksmith, git: "git://github.com/batate/blacksmith.git", only: :test},
    ]
  end

  defp aliases do
    [
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
