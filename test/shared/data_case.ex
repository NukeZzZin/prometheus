defmodule Prometheus.Test.DataCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PrometheusEntry.Endpoint
      use PrometheusEntry, :verified_routes
      import Plug.Conn
      import Phoenix.ConnTest
      import PrometheusEntry.Test.ConnCase
      import Prometheus.Test.DataCase
      import Ecto.Changeset
      alias Prometheus.Repository
      alias Prometheus.Redis
    end
  end

  setup context do
    Prometheus.Test.DataCase.setup_sandbox(context)
    :ok
  end

  @spec setup_sandbox(map()) :: :ok
  def setup_sandbox(context) do
    process_id = Ecto.Adapters.SQL.Sandbox.start_owner!(Prometheus.Repository, shared: not context[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(process_id) end)
    Prometheus.Redis.command(["FLUSHDB"])
    :ok
  end

  @spec errors_on(Ecto.Changeset.t()) :: %{optional(atom()) => [String.t()]}
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
      Regex.replace(~r"%{(\w+)}", message, fn _argument, key ->
        options
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
