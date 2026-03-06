defmodule PrometheusEntry.Router do
  use PrometheusEntry, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1/auth", PrometheusEntry do
    pipe_through [:api]
  end
end
