import Config

config :prometheus,
  ecto_repos: [Prometheus.Repository],
  generators: [timestamp_type: :utc_datetime_usec, binary_id: true]

config :prometheus, PrometheusEntry.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [json: PrometheusEntry.Controllers.ErrorJSON], layout: false],
  adapter: Bandit.PhoenixAdapter,
  pubsub_server: Prometheus.PubSubServer

config :logger, :console,
  format: "$time [$level] ($metadata) node=$node - $message\n",
  metadata: [:request_id],
  colors: [enabled: true, debug: :cyan, info: :green, warn: :yellow, error: :red]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
