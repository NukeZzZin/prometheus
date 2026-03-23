import Config

config :prometheus, PrometheusEntry.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  exclude: [hosts: ["localhost", "127.0.0.1"]]

config :logger, :console,
  level: :info,
  format: "$date $time [$level] ($metadata) node=$node - $message\n",
  metadata: [:request_id],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]
