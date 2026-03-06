import Config

config :prometheus,
  ecto_repos: [Prometheus.Repository],
  generators: [timestamp_type: :utc_datetime_usec, binary_id: true]

config :prometheus, PrometheusEntry.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    # formats: [json: PrometheusEntry.Controllers.ErrorJSON],
    layout: false
  ],
  pubsub_server: Prometheus.PubSub,
  live_view: [signing_salt: "WvWUoAcwBceLeJSusD"]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
