import Config

config :prometheus, Prometheus.Repository,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :prometheus, PrometheusEntry.Endpoint,
  check_origin: false,
  debug_errors: true

config :logger, :console,
  level: :debug,
  format: "$time [$level] ($metadata) node=$node - $message\n",
  metadata: [:request_id, :module, :function, :line],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
