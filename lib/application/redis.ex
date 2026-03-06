defmodule Prometheus.Redis do
  @behaviour NimblePool

  @default_command_timeout 5_000
  @default_checkout_timeout 15_000
  @default_child_shutdown 2_000

  @spec child_spec(keyword()  ) :: Supervisor.child_spec()
  def child_spec(options \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [options]},
      type: :worker,
      restart: :permanent,
      shutdown: @default_child_shutdown
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(options \\ []) do
    worker_config = Application.fetch_env!(:prometheus, __MODULE__)
    |> Keyword.fetch!(:redis)
    |> Keyword.merge(options)
    |> Keyword.put_new(:sync_connect, true)

    NimblePool.start_link(
      worker: {__MODULE__, worker_config},
      pool_size: Keyword.get(worker_config, :pool_size, System.schedulers_online() * 2),
      name: __MODULE__
    )
  end

  @impl NimblePool
  def init_worker(config) do
    case Redix.start_link(config) do
      {:ok, connection} ->
        {:ok, connection, config}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, connection, pool_state) do
    if Process.alive?(connection) do
      {:ok, connection, connection, pool_state}
    else
      {:remove, {:error, :closed}, connection, pool_state}
    end
  end

  @impl NimblePool
  def handle_checkin(_state, _from, connection, pool_state) do
    if Process.alive?(connection) do
      {:ok, connection, pool_state}
    else
      {:remove, {:error, :closed}, connection, pool_state}
    end
  end

  @impl NimblePool
  def terminate_worker(_reason, connection, pool_state) do
    Redix.stop(connection)
    {:ok, pool_state}
  end

  @spec command(list() | binary(), keyword()) :: {:ok, term()} | {:error, term()}
  def command(payload, options \\ [])
  def command(payload, options) when is_list(payload), do: execute(:command, payload, options)
  def command(payload, options) when is_binary(payload), do: execute(:command, [payload], options)

  @spec pipeline(list(), keyword()) :: {:ok, term()} | {:error, term()}
  def pipeline(payload, options \\ [])
  def pipeline(payload, options) when is_list(payload), do: execute(:pipeline, payload, options)

  @spec transaction_pipeline(list(), keyword()) :: {:ok, term()} | {:error, term()}
  def transaction_pipeline(payload, options \\ [])
  def transaction_pipeline(payload, options) when is_list(payload), do: execute(:transaction_pipeline, payload, options)

  # * === Helpers === * #
  @spec execute(atom(), list(), keyword()) :: {:ok, term()} | {:error, term()}
  defp execute(type, payload, options) do
    command_timeout = Keyword.get(options, :command_timeout, @default_command_timeout)
    checkout_timeout = Keyword.get(options, :checkout_timeout, @default_checkout_timeout)
    try do
      NimblePool.checkout!(
      __MODULE__,
      :checkout,
      fn _from, connection ->
        case apply(Redix, type, [connection, payload, [timeout: command_timeout]]) do
          {:ok, result} ->
            {{:ok, result}, :ok}
          {:error, %Redix.ConnectionError{}} ->
            {{:error, :closed}, :remove}
          {:error, reason} ->
            {{:error, reason}, :ok}
        end
      end,
      checkout_timeout)
    catch
      :exit, {:timeout, _} ->
        {:error, :checkout_timeout}
      :exit, _ ->
        {:error, :pool_error}
    end
  end
end
