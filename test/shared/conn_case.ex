defmodule PrometheusEntry.Test.ConnCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint PrometheusEntry.Endpoint
      use PrometheusEntry, :verified_routes
      import Plug.Conn
      import Phoenix.ConnTest
      import PrometheusEntry.Test.ConnCase
    end
  end

  setup tags do
    Prometheus.Test.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
