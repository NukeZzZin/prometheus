import Config

config :prometheus, Prometheus.Repository,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: "prometheus_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOSTNAME", "localhost"),
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
  
config :prometheus, Prometheus.Redis,
  pool_size: System.schedulers_online() * 2,
  redis: [
    host: System.get_env("REDIS_HOST", "localhost"),
    port: String.to_integer(System.get_env("REDIS_PORT", "6379")),
    password: System.get_env("REDIS_PASSWORD", "redis")
  ]

config :prometheus, PrometheusEntry.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4002],
  secret_key_base: "VChJ95enp7DSD8L6VhWT9u5HOpDM0lR7jadukgfQKE5c1zPECvThwkcGYOLLyBW+",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
config :phoenix, sort_verified_routes_query_params: true

config :argon2_elixir,
  argon2_type: 2,
  t_cost: 1,
  m_cost: 8,
  parallelism: String.to_integer(System.get_env("ARGON_THREADS") || "#{System.schedulers_online()}")
