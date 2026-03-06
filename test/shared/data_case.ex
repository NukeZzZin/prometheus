defmodule Prometheus.Test.DataCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Prometheus.Repository
      import Ecto
      import Ecto.{Changeset, Query}
      import Prometheus.Test.DataCase
    end
  end

  setup tags do
    Prometheus.Test.DataCase.setup_sandbox(tags)
    :ok
  end

  @spec setup_sandbox(map()) :: :ok
  def setup_sandbox(tags) do
    process_id = Ecto.Adapters.SQL.Sandbox.start_owner!(Prometheus.Repository, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(process_id) end)
  end

  @spec errors_on(Ecto.Changeset.t()) :: %{atom() => [String.t()]}
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
