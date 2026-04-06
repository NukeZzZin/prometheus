defmodule PrometheusEntry.Controllers.AccountController do
  use PrometheusEntry, :controller
  alias Prometheus.Contexts.AccountContext
  action_fallback PrometheusEntry.Controllers.FallbackController

  @spec register(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def register(connection, %{"username" => _, "display_name" => _, "email" => _, "password" => _} = parameters) do
    if connection.assigns[:current_user] != nil do
      {:error, :forbidden}
    else
      case AccountContext.register_user(parameters) do
        {:ok, tuple_tokens} ->
          connection
          |> put_status(:created)
          |> json(%{success: true, data: tuple_tokens})
        {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
        _ -> {:error, :internal_server_error}
      end
    end
  end
  def register(_connection, _parameters), do: {:error, :bad_request}

  @spec login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def login(connection, %{"identifier" => _, "password" => _} = parameters) do
    if connection.assigns[:current_user] != nil do
      {:error, :forbidden}
    else
      case AccountContext.login_user(parameters) do
        {:ok, tuple_tokens} ->
          connection
          |> put_status(:ok)
          |> json(%{success: true, data: tuple_tokens})
        _ -> {:error, :unauthorized}
      end
    end
  end
  def login(_connection, _parameters), do: {:error, :bad_request}
end
