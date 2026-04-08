defmodule Prometheus.Mix do
  use Mix.Project

  def project do
    [
      app: :prometheus,
      version: "0.1.1-dev",
      elixir: ">= 1.19.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      cli: cli(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Prometheus.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs:
      [
        "project.test": :test,
        "project.check": :test,
        "project.precommit": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/shared"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # * === Dependencies for main application === * #
      {:phoenix, "~> 1.8.5"},
      {:phoenix_ecto, "~> 4.7.0"},
      {:phoenix_pubsub, "~> 2.2.0"},
      {:bandit, "~> 1.10.3"},
      {:corsica, "~> 2.1.3"},

      # * === Dependencies for serialization and deserialization === * #
      {:jason, "~> 1.4.4"},

      # * === Dependencies for hashing and security === * #
      {:argon2_elixir, "~> 4.1.3"},
      {:snowflake, "~> 1.0.4"},
      {:joken, "~> 2.6.2"},

      # * === Dependencies for database and cache === * #
      {:ecto_sql, "~> 3.13.5"},
      {:postgrex, ">= 0.22.0"},
      {:nimble_pool, ">= 1.1.0"},
      {:redix, "~> 1.5.3"},

      # * === Dependencies for environment variables === * #
      {:dotenvy, "~> 1.1.1"},

      # * === Dependencies for development and testing === * #
      {:dialyxir, "~> 1.4.7", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7.17", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "project.prepare": ["deps.get", "deps.compile", "ecto.setup"],
      "project.reset": ["deps.clean --all", "deps.get", "compile --warnings-as-errors", "ecto.rebuild"],

      "project.test": ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "project.check": ["format --check-formatted", "credo --all --strict", "dialyzer"],
      "project.precommit": ["compile --warnings-as-errors", "project.check", "project.test"],

      "ecto.setup": ["ecto.create --quiet", "ecto.migrate", "run priv/repository/seeds.exs"],
      "ecto.rebuild": ["ecto.drop", "ecto.setup"],

      "deps.reset": ["deps.clean --all", "deps.get", "deps.compile"],
      "deps.recompile": ["deps.clean --build", "deps.get", "deps.compile"]
    ]
  end
end
