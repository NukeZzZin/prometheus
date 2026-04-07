defmodule Prometheus.Repository do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :prometheus,
    adapter: Ecto.Adapters.Postgres
end
