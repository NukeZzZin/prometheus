defmodule PrometheusEntry.Middlewares.AuthMiddleware do
  @behaviour Plug

  import Plug.Conn

  alias Prometheus.Utils.TokenUtil

  @impl Plug
  def init(options), do: options

  @impl Plug
  def call(connection, _options) do
    with {:ok, token} <- extract_connection_token(connection),
      {:ok, claims} <- TokenUtil.verify_access_token(token) do
        assign(connection, :current_user, claims)
    else
      _ ->
        connection
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, "")
        |> halt()
    end
  end

  # * === Helpers === * #
  @spec extract_connection_token(Plug.Conn.t()) :: {:ok, Joken.bearer_token()} | {:error, :invalid_connection_token}
  defp extract_connection_token(connection) do
    case get_req_header(connection, "authorization") do
      ["Bearer " <> bearer_token] ->
        {:ok, String.trim(bearer_token)}
      _ ->
        {:error, :invalid_connection_token}
    end
  end
end
