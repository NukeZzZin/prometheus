defmodule PrometheusEntry.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  @poller_period 10_000

  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(argument) do
    Supervisor.start_link(__MODULE__, argument, name: __MODULE__)
  end

  @impl Supervisor
  def init(_argument) do
    children = [
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()},
      {:telemetry_poller, measurements: periodic_measurements(), period: @poller_period}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec metrics() :: [Telemetry.Metrics.t()]
  def metrics do
    [
      # * === Phoenix Metrics === * #
      summary("phoenix.endpoint.start.system_time", unit: {:native, :millisecond}),
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.start.system_time", tags: [:route], unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.exception.duration", tags: [:route], unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration", tags: [:route], unit: {:native, :millisecond}),
      summary("phoenix.socket_connected.duration", unit: {:native, :millisecond}),
      summary("phoenix.channel_joined.duration", unit: {:native, :millisecond}),
      summary("phoenix.channel_handled_in.duration", tags: [:event], unit: {:native, :millisecond}),
      sum("phoenix.socket_drain.count"),

      # * === Postgres Metrics === * #
      summary("prometheus.repository.query.total_time", unit: {:native, :millisecond}, description: "The sum of the other measurements"),
      summary("prometheus.repository.query.decode_time", unit: {:native, :millisecond}, description: "The time spent decoding the data received from the database"),
      summary("prometheus.repository.query.query_time", unit: {:native, :millisecond}, description: "The time spent executing the query"),
      summary("prometheus.repository.query.queue_time", unit: {:native, :millisecond}, description: "The time spent waiting for a database connection"),
      summary("prometheus.repository.query.idle_time", unit: {:native, :millisecond}, description: "The time the connection spent waiting before being checked out for the query"),

      # * === Virtual Machine Metrics === * #
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {PrometheusEntry, :count_users, []}
    ]
  end
end
