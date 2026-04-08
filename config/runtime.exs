import Config

secret_key_base = System.get_env("SECRET_KEY_BASE") || :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64)
jwt_secret_key = System.get_env("JWT_SECRET_KEY") || :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64)
env_dir_prefix = System.get_env("RELEASE_ROOT") || Path.expand(".")

Dotenvy.source!([
  Path.join(env_dir_prefix, ".env"),
  Path.join(env_dir_prefix, ".env.#{config_env()}"),
  System.get_env()
])

config :joken, default_signer: jwt_secret_key

config :snowflake,
  epoch: 1_767_268_800, # ! 2026-01-01 12:00:00 (default)
  machine_id: Dotenvy.env!("MACHINE_ID", :integer, :erlang.phash2(:erlang.node(), 1024))

if Dotenvy.env!("PHX_SERVER", :boolean, false), do: config(:prometheus, PrometheusEntry.Endpoint, server: true)

postgres_pool_size = Dotenvy.env!("POSTGRES_POOL_SIZE", :integer, :erlang.system_info(:schedulers_online) * 2)

case Dotenvy.env!("DATABASE_URL", :string?, nil) do
  nil ->
    config :prometheus, Prometheus.Repository,
      username: Dotenvy.env!("POSTGRES_USER", :string, "postgres"),
      password: Dotenvy.env!("POSTGRES_PASSWORD", :string, "postgres"),
      hostname: Dotenvy.env!("POSTGRES_HOST", :string, "localhost"),
      port: Dotenvy.env!("POSTGRES_PORT", :integer, 5432),
      pool_size: postgres_pool_size

  database_url ->
    config :prometheus, Prometheus.Repository,
      url: database_url,
      socket_options: if(Dotenvy.env!("ECTO_IPV6", :boolean, false), do: [:inet6], else: []),
      pool_size: postgres_pool_size
end

redis_pool_size = Dotenvy.env!("REDIS_POOL_SIZE", :integer, :erlang.system_info(:schedulers_online) * 2)

config :prometheus, Prometheus.Redis,
  host: Dotenvy.env!("REDIS_HOST", :string, "localhost"),
  password: Dotenvy.env!("REDIS_PASSWORD", :string, "redis"),
  port: Dotenvy.env!("REDIS_PORT", :integer, 6379),
  pool_size: redis_pool_size

phoenix_server_port = Dotenvy.env!("PHX_PORT", :integer, 4000)

case config_env() do
  :dev ->
    config :prometheus, Prometheus.Repository,
      database: Dotenvy.env!("POSTGRES_DB", :string, "prometheus_dev")

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: phoenix_server_port],
      secret_key_base: secret_key_base

  :prod ->
    config :prometheus, Prometheus.Repository,
      database: Dotenvy.env!("POSTGRES_DB", :string, "prometheus_prod")

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: phoenix_server_port],
      url: [host: if(Dotenvy.env!("PHX_HOST", :string, nil) != nil, do: Dotenvy.env!("PHX_HOST", :string, "prometheus.com"), else: nil)],
      secret_key_base: secret_key_base

  :test ->
    config :prometheus, Prometheus.Repository,
      database: Dotenvy.env!("POSTGRES_DB", :string, "prometheus_test") <> Dotenvy.env!("MIX_TEST_PARTITION", :string, "1")

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: phoenix_server_port],
      secret_key_base: secret_key_base
end
