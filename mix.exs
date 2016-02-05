defmodule Sentinel.Mixfile do
  use Mix.Project

  @version "0.0.4"
  @source_url "https://github.com/britton-jb/sentinel"

  def project do
    [app: :sentinel,
      version: @version,
      elixir: "~> 1.1",
      package: package,
      description: description,
      source_url: @source_url,
      deps: deps]
  end


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
    :ueberauth,
    :ecto,
    :postgrex,
    :phoenix
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
      {:guardian, "~> 0.9.0"},
      {:guardian_db, "~> 0.4.0"},
      {:ueberauth, "~> 0.2"},
      {:secure_random, "~> 0.2"},
      {:comeonin, "~> 2.0"},
      {:mailman, github: "Joe-noh/mailman"},
      {:eiconv, github: "zotonic/eiconv"},

      {:cowboy, "~> 1.0.0"},
      {:phoenix, "~> 1.1.0"},
      {:ecto, "~> 1.0"},
      {:postgrex, ">= 0.6.0"},
      {:jose, "~> 1.4"},

      # DEV
      {:earmark, ">= 0.0.0"},
      {:ex_doc, ">= 0.6.0"},
      # TESTING
      {:mock, "~> 0.1.0", only: :test},
      {:blacksmith, git: "git://github.com/batate/blacksmith.git", only: :test},
    ]
  end
end
