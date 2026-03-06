import Config

config :prometheus, Prometheus.Repository,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "prometheus_dev"),
  hostname: System.get_env("POSTGRES_HOSTNAME", "localhost"),
  port: 5432,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: System.schedulers_online() * 2

config :prometheus, Prometheus.Redis,
  pool_size: System.schedulers_online() * 2,
  redis: [
    host: System.get_env("REDIS_HOST", "localhost"),
    port: String.to_integer(System.get_env("REDIS_PORT", "6379")),
    password: System.get_env("REDIS_PASSWORD", "redis")
  ]

config :prometheus, PrometheusEntry.Endpoint,
  http: [ip: {0, 0, 0, 0}],
  check_origin: false,
  code_reloader: false,
  debug_errors: true,
  secret_key_base: "h7iDvAAe6ZmiDScaEqZKm5bU1C40X4gl/eiok9XPjFgOeINuiFr/04L94VXCuKrJ",
  watchers: []

config :logger, :default_formatter, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
