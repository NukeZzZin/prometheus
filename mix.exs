defmodule Prometheus.Mix do
  use Mix.Project

  def project do
    [
      app: :prometheus,
      version: "0.1.0-dev",
      elixir: ">= 1.17.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      name: "Prometheus",
      description: "⛓ Prometheus Backend ⛓",
      license: "GNU Affero General Public License v3.0"
    ]
  end

  def application do
    [
      mod: {Prometheus.Application, []},
      extra_applications: [:logger, :runtime_tools, :crypto, :ssl]
    ]
  end

  def cli do
    [
      preferred_envs:
      [
        "project.test": :test,
        "project.precommit": :test
      ]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.5"},
      {:phoenix_ecto, "~> 4.7.0"},
      {:phoenix_pubsub, "~> 2.2.0"},

      {:jason, "~> 1.4.4"},
      {:bandit, "~> 1.10.3"},
      {:corsica, "~> 2.1.3"},

      {:argon2_elixir, "~> 4.1.3"},
      {:snowflake, "~> 1.0.4"},
      {:joken, "~> 2.6.2"},
      {:dotenvy, "~> 1.1.1"},

      {:ecto_sql, "~> 3.13.5"},
      {:postgrex, ">= 0.22.0"},
      {:nimble_pool, ">= 1.1.0"},
      {:redix, "~> 1.5.3"},

      {:telemetry_metrics, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.3.0"},

      {:dialyxir, "~> 1.4.7", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7.17", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "project.start": ["project.setup", "phx.server"],
      "project.setup": ["deps.get", "deps.compile", "ecto.setup"],
      "project.test": ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "project.precommit": ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"],
      "project.check": ["format --check-formatted", "credo --strict"],

      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],

      "deps.reset": ["deps.clean --all", "deps.get", "deps.compile"],
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/shared"]
  defp elixirc_paths(_), do: ["lib"]
end
