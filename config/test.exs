import Config

config :prometheus, PrometheusEntry.Endpoint, server: false

config :logger, :console,
  level: :warning,
  format: "$time [$level] ($metadata) node=$node - $message\n",
  metadata: [:request_id, :module, :function, :line],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]

config :phoenix, :plug_init_mode, :runtime
config :phoenix, sort_verified_routes_query_params: true
