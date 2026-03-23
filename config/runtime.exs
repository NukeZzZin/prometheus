import Config

env_dir_prefix = System.get_env("RELEASE_ROOT") || Path.expand(".")

Dotenvy.source!(
  [
    Path.absname(".env", env_dir_prefix),
    Path.absname(".env.#{config_env()}", env_dir_prefix),
    System.get_env()
  ],
  require_files: [Path.absname(".env", env_dir_prefix)]
)

config :joken,
  default_signer: Joken.Signer.create("HS256", Dotenvy.env!("JWT_SECRET_KEY", :string!))

config :argon2_elixir,
  argon2_type: 2,
  t_cost: 2,
  m_cost: 16,
  parallelism: Dotenvy.env!("ARGON_THREADS", :integer, div(System.schedulers_online(), 2))

config :snowflake,
  epoch: 1_767_268_800,
  machine_id: :erlang.phash2(Node.self(), 1024)

if Dotenvy.env!("PHX_SERVER", :boolean, false) do
  config :prometheus, PrometheusEntry.Endpoint, server: true
end

postgres_pool_size = Dotenvy.env!("POSTGRES_POOL_SIZE", :integer, System.schedulers_online() * 2)

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

redis_pool_size = Dotenvy.env!("REDIS_POOL_SIZE", :integer, System.schedulers_online() * 2)

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
      http: [ip: {127, 0, 0, 1}, port: phoenix_server_port]

  :prod ->
    config :prometheus, Prometheus.Repository,
      database: Dotenvy.env!("POSTGRES_DB", :string, "prometheus_prod")

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: phoenix_server_port],
      url: [host: Dotenvy.env!("PHX_HOST", :string, "prometheus.com"), port: 443, scheme: "https"],
      secret_key_base: Dotenvy.env!("SECRET_KEY_BASE", :string!)

  :test ->
    config :prometheus, Prometheus.Repository,
      database:
        Dotenvy.env!("POSTGRES_DB", :string, "prometheus_test") <>
          Dotenvy.env!("MIX_TEST_PARTITION", :string, "1")

    config :prometheus, PrometheusEntry.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: phoenix_server_port]
end
