import Config
import Dotenvy

env_dir_prefix = System.get_env("RELEASE_ROOT") || Path.expand(".")
env_object = Dotenvy.source!([Path.join(env_dir_prefix, ".env"), Path.join(env_dir_prefix, ".env.#{config_env()}"), System.get_env()])
System.put_env(env_object)

secret_key_base = System.get_env("SECRET_KEY_BASE") || if(config_env() in [:dev, :test],
  do: :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64),
  else: raise"Set SECRET_KEY_BASE in your environment file.")
jwt_secret_key = System.get_env("JWT_SECRET_KEY") || if(config_env() in [:dev, :test],
  do: :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64),
  else: raise"Set JWT_SECRET_KEY in your environment file.")

config :joken, default_signer: jwt_secret_key

config :snowflake,
  epoch: 1_767_268_800, # ! 2026-01-01 12:00:00 (default)
  machine_id: String.to_integer(System.get_env("MACHINE_ID")) || :erlang.phash2(:erlang.node(), 1024)

if System.get_env("PHX_SERVER"), do: config(:prometheus, PrometheusEntry.Endpoint, server: true)

postgres_pool_size = String.to_integer(System.get_env("POSTGRES_POOL_SIZE")) || :erlang.system_info(:schedulers_online) * 2

case System.get_env("DATABASE_URL") do
  nil ->
    config :prometheus, Prometheus.Repository,
      username: System.get_env("POSTGRES_USER") || "postgres",
      password: System.get_env("POSTGRES_PASSWORD") || "postgres",
      hostname: System.get_env("POSTGRES_HOST") || "localhost",
      port: System.get_env("POSTGRES_PORT") || 5432,
      pool_size: postgres_pool_size

  database_url ->
    config :prometheus, Prometheus.Repository,
      url: database_url,
      socket_options: if(System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []),
      pool_size: postgres_pool_size
end

redis_pool_size = String.to_integer(System.get_env("REDIS_POOL_SIZE")) || :erlang.system_info(:schedulers_online) * 2

config :prometheus, Prometheus.Redis,
  host: System.get_env("REDIS_HOST") || "localhost",
  password: System.get_env("REDIS_PASSWORD") || "redis",
  port: String.to_integer(System.get_env("REDIS_PORT")) || 6379,
  pool_size: redis_pool_size

phoenix_server_port = String.to_integer(System.get_env("PHX_PORT")) || 4000

case config_env() do
  :dev ->
    config :prometheus, Prometheus.Repository,
      database: System.get_env("POSTGRES_DB") || "prometheus_dev"

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: phoenix_server_port],
      secret_key_base: secret_key_base

  :prod ->
    config :prometheus, Prometheus.Repository,
      database: System.get_env("POSTGRES_DB") || "prometheus_prod"

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: phoenix_server_port],
      secret_key_base: secret_key_base

  :test ->
    config :prometheus, Prometheus.Repository,
      database: System.get_env("POSTGRES_DB") || "prometheus_test" <> System.get_env("MIX_TEST_PARTITION") || "1"

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: phoenix_server_port],
      secret_key_base: secret_key_base
end
