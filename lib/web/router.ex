defmodule PrometheusEntry.Router do
  use PrometheusEntry, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug PrometheusEntry.Middlewares.AuthMiddleware
  end

  scope "/api/v1", PrometheusEntry.Controllers do
    pipe_through [:api]

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login

    post "/session/refresh", SessionController, :refresh
  end

  scope "/api/v1", PrometheusEntry.Controllers do
    pipe_through [:api, :authenticated]

    post "/logout", SessionController, :logout
  end
end
