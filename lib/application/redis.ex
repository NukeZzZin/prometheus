defmodule Prometheus.Redis do
  @moduledoc false
  @behaviour NimblePool
  @default_command_timeout 5_000
  @default_checkout_timeout 15_000
  @default_child_shutdown 2_000

  # * === NimblePool Callbacks === * #
  @impl NimblePool
  def init_worker(config) do
    case Redix.start_link(config) do
      {:ok, connection} -> {:ok, connection, config}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, connection, pool_state) do
    if Process.alive?(connection),
      do: {:ok, connection, connection, pool_state},
      else: {:remove, {:error, :closed}, connection, pool_state}
  end

  @impl NimblePool
  def handle_checkin(_state, _from, connection, pool_state) do
    if Process.alive?(connection),
      do: {:ok, connection, pool_state},
      else: {:remove, {:error, :closed}, connection, pool_state}
  end

  @impl NimblePool
  def terminate_worker(_reason, connection, pool_state) do
    Redix.stop(connection)
    {:ok, pool_state}
  end

  # * === Public Functions === * #
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(options \\ []), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [options]}, type: :worker, restart: :permanent, shutdown: @default_child_shutdown}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(options \\ []) do
    nimble_config = :prometheus
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.merge(options)
    worker_config = nimble_config
    |> Keyword.take([:host, :port, :password, :database, :socket_opts, :sync_connect])
    |> Keyword.put_new(:sync_connect, true)
    pool_size = Keyword.get(nimble_config, :pool_size, :erlang.system_info(:schedulers_online) * 2)
    NimblePool.start_link(worker: {__MODULE__, worker_config}, pool_size: pool_size, name: __MODULE__)
  end

  @spec command(String.Chars.t(), keyword()) :: {:ok, Redix.Protocol.redis_value()} | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def command(payload, options \\ []) when is_list(payload), do: execute(:command, payload, options)

  @spec pipeline(String.Chars.t(), keyword()) :: {:ok, [Redix.Protocol.redis_value()]} | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def pipeline(payload, options \\ []) when is_list(payload), do: execute(:pipeline, payload, options)

  @spec transaction_pipeline(String.Chars.t(), keyword()) :: {:ok, [Redix.Protocol.redis_value()]} | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def transaction_pipeline(payload, options \\ []) when is_list(payload), do: execute(:transaction_pipeline, payload, options)

  # * === Private Helpers === * #
  @spec execute(atom(), list(), keyword()) :: {:ok, term()} | {:error, term()}
  defp execute(type, payload, options) do
    command_timeout = Keyword.get(options, :command_timeout, @default_command_timeout)
    checkout_timeout = Keyword.get(options, :checkout_timeout, @default_checkout_timeout)
    try do
      NimblePool.checkout!(
        __MODULE__,
        :checkout,
        fn _from, connection ->
          case apply(Redix, type, [connection, apply_prefix(payload, Process.get(:redis_namespace, nil)), [timeout: command_timeout]]) do
            {:ok, result} -> {{:ok, result}, :ok}
            {:error, %Redix.ConnectionError{}} -> {{:error, :closed}, :remove}
            {:error, reason} -> {{:error, reason}, :ok}
          end
        end,
        checkout_timeout
      )
    catch
      :exit, {:timeout, _} -> {:error, :checkout_timeout}
      :exit, _ -> {:error, :pool_error}
    end
  end

  # TODO: Lembre-se de testar se realmente multi-thread resultou em melhorias no tempo de testes
  @spec apply_prefix(list() | tuple(), binary() | nil) :: list() | tuple()
  defp apply_prefix(payload, nil), do: payload
  defp apply_prefix([head | _] = pipeline, prefix) when is_list(head), do: Enum.map(pipeline, &prefix_command(&1, prefix))
  defp apply_prefix(command, prefix) when is_list(command), do: prefix_command(command, prefix)
  defp prefix_command([action | rest] = command, prefix) do
    case rest do
        [] -> command
        [head_rest | tail_rest] -> cond do
          action in ["PING", "INFO", "FLUSHDB", "SELECT", "AUTH"] -> command
          is_nil(prefix) or String.starts_with?(head_rest, prefix) -> command
          true -> [action, "#{prefix}#{head_rest}" | tail_rest]
        end
    end
  end
end
