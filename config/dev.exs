import Config

config :prometheus, Prometheus.Repository,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :prometheus, PrometheusEntry.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  debug_errors: true,
  secret_key_base: "h7iDvAAe6ZmiDScaEqZKm5bU1C40X4gl/eiok9XPjFgOeINuiFr/04L94VXCuKrJ",
  watchers: []

config :logger, :console, level: :debug,
  format: "$time [$level] ($metadata\0node=$node) - $message\n", metadata: [:request_id, :module, :function],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
