import Config

config :prometheus, PrometheusEntry.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4002],
  debug_errors: true,
  secret_key_base: "VChJ95enp7DSD8L6VhWT9u5HOpDM0lR7jadukgfQKE5c1zPECvThwkcGYOLLyBW+",
  server: false

config :logger, :console, level: :warning,
  format: "$time $metadata[$level] ($node) - $message\n", metadata: [:request_id, :module, :function],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]
config :phoenix, :plug_init_mode, :runtime
config :phoenix, sort_verified_routes_query_params: true
