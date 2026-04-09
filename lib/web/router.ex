defmodule PrometheusEntry.Router do
  @moduledoc false
  use PrometheusEntry, :router

  pipeline :general do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug :accepts, ["json"]
    plug PrometheusEntry.Middlewares.AuthMiddleware
  end

  # TODO: Lembre-se de implementar os testes para todos os controllers.
  scope "/api/v1", PrometheusEntry.Controllers do
    pipe_through [:general]
    get "/posts", PostController, :list_posts
    get "/posts/:id", PostController, :get_post
    get "/users/:id/posts", PostController, :list_user_posts
    post "/auth/register", AccountController, :register
    post "/auth/login", AccountController, :login
    post "/session/refresh", SessionController, :refresh
    post "/session/logout", SessionController, :logout
  end

  scope "/api/v1", PrometheusEntry.Controllers do
    pipe_through [:authenticated]
    post "/posts/create", PostController, :create_post
  end
end
