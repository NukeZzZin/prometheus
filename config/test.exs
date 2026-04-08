import Config

config :prometheus, PrometheusEntry.Endpoint, server: false
config :prometheus, Prometheus.Repository, pool: Ecto.Adapters.SQL.Sandbox

config :argon2_elixir, argon2_type: 2, t_cost: 1, m_cost: 4, parallelism: 1

config :logger, :console,
  level: :warning,
  format: "$time [$level] ($metadata) node=$node - $message\n",
  metadata: [:request_id, :module, :function, :line],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]

config :phoenix, :plug_init_mode, :runtime
config :phoenix, sort_verified_routes_query_params: true
