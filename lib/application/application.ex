defmodule Prometheus.Application do
  use Application

  @impl Application
  def start(_type, _arguments) do
    children = [
      Prometheus.Repository,
      Prometheus.Redis,
      {Phoenix.PubSub, name: Prometheus.PubSub},
      PrometheusEntry.Telemetry,
      PrometheusEntry.Endpoint
    ]
    options = [strategy: :one_for_one, name: Prometheus.Supervisor]
    Supervisor.start_link(children, options)
  end

  @impl Application
  def config_change(changed, _new, removed) do
    PrometheusEntry.Endpoint.config_change(changed, removed)
    :ok
  end
end
