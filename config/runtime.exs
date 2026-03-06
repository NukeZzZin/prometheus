import Config

if System.get_env("PHX_SERVER") do
  config :prometheus, PrometheusEntry.Endpoint, server: true
end

config :prometheus, PrometheusEntry.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

config :joken,
  default_signer: System.get_env("JWT_SECRET")


config :argon2_elixir,
  argon2_type: 2,
  t_cost: 2,
  m_cost: 16,
  parallelism: String.to_integer(System.get_env("ARGON_THREADS") || "#{System.schedulers_online()}")

config :snowflake,
  nodes: ["127.0.0.1", "prometheus@nodehost"],
  epoch: 1_770_864_148_694

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing.\nFor example: ecto://USER:PASS@HOST/DATABASE"

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :prometheus, Prometheus.Redis,
    pool_size: String.to_integer(System.get_env("POSTGRES_POOL_SIZE") || "#{System.schedulers_online() * 2}"),
    redis: [
      host: System.get_env("REDIS_HOST", "localhost"),
      port: String.to_integer(System.get_env("REDIS_PORT", "6379")),
      password: System.get_env("REDIS_PASSWORD", "redis")
    ]

  config :prometheus, Prometheus.Repository,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POSTGRES_POOL_SIZE") || "#{System.schedulers_online() * 2}"),
    socket_options: maybe_ipv6

  secret_base =
    System.get_env("SECRET_BASE") ||
      raise "environment variable SECRET_BASE is missing.\nYou can generate one by calling: mix phx.gen.secret"

  host = System.get_env("PHX_HOST") || "example.com"

  config :prometheus, PrometheusEntry.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}],
    secret_key_base: secret_base
end
