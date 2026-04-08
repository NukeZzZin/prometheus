import Config

config :prometheus, PrometheusEntry.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  exclude: [hosts: ["localhost", "127.0.0.1"]]

config :argon2_elixir, argon2_type: 2, t_cost: 3, m_cost: 16, parallelism: 4

config :logger, :console,
  level: :info,
  format: "$date $time [$level] ($metadata) node=$node - $message\n",
  metadata: [:request_id],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]
