defmodule Prometheus.Test.DataCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PrometheusEntry.Endpoint
      use PrometheusEntry, :verified_routes
      import Plug.{Conn, Test}
      import Phoenix.ConnTest
      import PrometheusEntry.Test.ConnCase
      import Prometheus.Test.DataCase
      import Ecto.Changeset
      alias Prometheus.{Redis, Repository}
    end
  end

  setup context, do: Prometheus.Test.DataCase.setup_sandbox(context)

  @spec setup_sandbox(map()) :: :ok
  def setup_sandbox(context) do
    process_id = Ecto.Adapters.SQL.Sandbox.start_owner!(Prometheus.Repository, shared: not context[:async])
    redis_namespace = "test:#{Kernel.inspect(:erlang.self())}:"
    Process.put(:redis_namespace, redis_namespace)
    on_exit(fn ->
      if Process.alive?(process_id), do: Ecto.Adapters.SQL.Sandbox.stop_owner(process_id)
      with {:ok, redis_object} <- Prometheus.Redis.command(["KEYS", "#{redis_namespace}*"]), do: Prometheus.Redis.command(["DEL" | redis_object])
    end)
    :ok
  end

  @spec inject_mocking_user(map()) :: {:ok, [author_id: String.t(), user: Prometheus.Schemas.UserSchema.t()]}
  def inject_mocking_user(attributes \\ %{}) do
    unique_discriminator = System.unique_integer([:positive, :monotonic])
    default_attributes = %{"username" => "user_#{unique_discriminator}", "display_name" => "TestUser", "email" => "test_#{unique_discriminator}@test.com", "password" => "TestP@ssw0rd"}
    final_attributes = Map.merge(default_attributes, attributes)
    {:ok, _tuple_tokens} = Prometheus.Contexts.AccountContext.register_user(final_attributes)
    unique_user = Prometheus.Repository.get_by!(Prometheus.Schemas.UserSchema, username: "user_#{unique_discriminator}")
    {:ok, author_id: unique_user.id, user: unique_user}
  end

  @spec errors_on(Ecto.Changeset.t()) :: %{optional(atom()) => [String.t()]}
  def errors_on(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
      Regex.replace(~r"%{(\w+)}", message, fn _argument, key ->
        options
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
