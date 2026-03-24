defmodule PrometheusEntry.Router do
  use PrometheusEntry, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug :accepts, ["json"]
    plug PrometheusEntry.Middlewares.AuthMiddleware
  end

  scope "/api/v1", PrometheusEntry.Controllers do
    pipe_through [:api]

    scope "/posts" do
      get "/", PostController, :list
      get "/:id", PostController, :get
    end

    scope "/auth" do
      post "/register", AccountController, :register
      post "/login", AccountController, :login
    end

    scope "/session" do
      post "/refresh", SessionController, :refresh
      post "/logout", SessionController, :logout
    end
  end

  scope "/api/v1", PrometheusEntry.Controllers do
    pipe_through [:authenticated]

    scope "/posts" do
      post "/create", PostController, :create
    end
  end
end
