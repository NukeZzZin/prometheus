defmodule PrometheusEntry.Middlewares.AuthMiddleware do
  @behaviour Plug

  import Plug.Conn

  alias Prometheus.Utils.TokenUtil

  @impl Plug
  def init(options), do: options

  @impl Plug
  def call(connection, _options) do
    with {:ok, access_token} <- extract_connection_token(connection),
      {:ok, access_claims} <- TokenUtil.verify_access_token(access_token) do
        assign(connection, :current_user, access_claims)
    else
      {:error, :missing_token} ->
        connection
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, Jason.encode!(%{success: false, errors: [%{code: "MISSING_TOKEN", message: "Missing token"}]}))
        |> halt()
      {:error, :invalid_token} ->
        connection
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, Jason.encode!(%{success: false, errors: [%{code: "INVALID_TOKEN", message: "Invalid token"}]}))
        |> halt()
    end
  end

  # * === Helpers === * #
  @spec extract_connection_token(Plug.Conn.t()) ::
    {:ok, Joken.bearer_token()} | {:error, :missing_token}
  defp extract_connection_token(connection) do
    case get_req_header(connection, "authorization") do
      ["Bearer " <> bearer_token] ->
        {:ok, String.trim(bearer_token)}
      _ ->
        {:error, :missing_token}
    end
  end
end
