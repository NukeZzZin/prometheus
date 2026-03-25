defmodule PrometheusEntry.Controllers.SessionController do
  use PrometheusEntry, :controller

  alias Prometheus.Contexts.SessionContext

  @spec refresh(Plug.Conn.t(), %{refresh_token: String.t()}) :: Plug.Conn.t()
  def refresh(connection, %{"refresh_token" => current_token}) do
    case SessionContext.rotate_session(current_token) do
      {:ok, new_tuple_tokens} ->
        connection
        |> put_status(:ok)
        |> json(%{success: true, data: new_tuple_tokens})
      _ ->
        connection
        |> put_status(:unauthorized)
        |> json(%{success: false, errors: [%{code: "UNAUTHORIZED", message: "Invalid session"}]})
    end
  end

  def refresh(connection, _invalid), do:
    connection
    |> put_status(:bad_request)
    |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]})

  @spec logout(Plug.Conn.t(), %{refresh_token: String.t()}) :: Plug.Conn.t()
  def logout(connection, %{"refresh_token" => current_token}) do
    case SessionContext.revoke_session(current_token) do
      {:ok, :revoked_session} ->
        connection
        |> put_status(:ok)
        |> json(%{success: true, data: "Revoked session"})
      _ ->
        connection
        |> put_status(:unauthorized)
        |> json(%{success: false, errors: [%{code: "UNAUTHORIZED", message: "Invalid session"}]})
    end
  end

  def logout(connection, _invalid), do:
    connection
    |> put_status(:bad_request)
    |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]})
end
