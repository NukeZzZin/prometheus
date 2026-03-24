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
      get "/", PostController, :list_posts # ! === REQUEST
      get "/:id", PostController, :get_post # ! === REQUEST: { PARAMS: { id: integer } } #
    end

    scope "/users" do
      # TODO: Lembra de implementar as rotas para usuarios.
      get "/:id/posts", PostController, :list_user_posts # ! === REQUEST: { QUERY_PARAMS: { id: integer } } #
    end

    scope "/auth" do
      post "/register", AccountController, :register # ! === REQUEST: { FORM-DATA: { username: string, email: string, display_name: string, password: string } } #
      post "/login", AccountController, :login # ! === REQUEST: { FORM-DATA: { username: string, password: string } } #
    end

    scope "/session" do
      post "/refresh", SessionController, :refresh # ! === REQUEST: { FORM-DATA: { refresh_token: string } } #
      post "/logout", SessionController, :logout # ! === REQUEST: { FORM-DATA: { refresh_token: string } } #
    end
  end

  scope "/api/v1", PrometheusEntry.Controllers do
    pipe_through [:authenticated] # ! === REQUEST: { HEADER: "Authorization: Bearer" } #

    scope "/posts" do
      post "/create", PostController, :create_post # ! === REQUEST: { FORM-DATA: { title: string, content: string } } #
    end
  end
end
