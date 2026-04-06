defmodule PrometheusEntry.Controllers.SessionController do
  use PrometheusEntry, :controller
  alias Prometheus.Contexts.SessionContext
  action_fallback PrometheusEntry.Controllers.FallbackController

  @spec refresh(Plug.Conn.t(), %{refresh_token: String.t()}) :: Plug.Conn.t()
  def refresh(connection, %{"refresh_token" => current_token})  do
    case SessionContext.rotate_session(current_token) do
      {:ok, new_tuple_tokens} ->
        connection
        |> put_status(:ok)
        |> json(%{success: true, data: new_tuple_tokens})
      _ -> {:error, :unauthorized}
    end
  end
  def refresh(_connection, _parameters), do: {:error, :bad_request}

  @spec logout(Plug.Conn.t(), %{refresh_token: String.t()}) :: Plug.Conn.t()
  def logout(connection, %{"refresh_token" => current_token}) do
    case SessionContext.revoke_session(current_token) do
      {:ok, :revoked_session} ->
        connection
        |> put_status(:ok)
        |> json(%{success: true, data: "Revoked session"})
      _ -> {:error, :unauthorized}
    end
  end
  def logout(_connection, _parameters), do: {:error, :bad_request}
end
