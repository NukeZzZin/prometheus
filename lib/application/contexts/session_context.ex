defmodule Prometheus.Contexts.SessionContext do
  alias Prometheus.Redis
  alias Prometheus.Utils.TokenUtil

  @refresh_expiration 604_800 # * (7*24*60*60=604800) seconds - 7 days

  @spec create_session(pos_integer()) ::
    {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, :internal_server_error}
  def create_session(identifier) when is_integer(identifier) do
    with {:ok, access_token, _, refresh_token, refresh_claims} <- TokenUtil.generate_tuple_token(identifier),
      {:ok, :stored_session} <- store_refresh_session(refresh_claims["jti"], refresh_claims["sub"]) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec rotate_session(Joken.bearer_token()) ::
    {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, :internal_server_error}
  def rotate_session(old_token) when is_binary(old_token) do
    with {:ok, old_claims} <- TokenUtil.verify_refresh_token(old_token),
      {:ok, :deleted_session} <- delete_refresh_session(old_claims["jti"]),
      {:ok, access_token, _, refresh_token, refresh_claims} <- TokenUtil.generate_tuple_token(old_claims["sub"]),
      {:ok, :stored_session} <- store_refresh_session(refresh_claims["jti"], refresh_claims["sub"]) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec revoke_session(Joken.bearer_token()) ::
    {:ok, :revoked_session} | {:error, :internal_server_error}
  def revoke_session(refresh_token) when is_binary(refresh_token) do
    with {:ok, refresh_claims} <- TokenUtil.verify_refresh_token(refresh_token),
      {:ok, :deleted_session} <- delete_refresh_session(refresh_claims["jti"]) do
        {:ok, :revoked_session}
    else
      _ ->
        {:error, :internal_server_error}
    end
  end

  # * === Helpers === * #
  @spec store_refresh_session(binary(), pos_integer()) ::
    {:ok, :stored_session} | {:error, :internal_server_error}
  defp store_refresh_session(refresh_identifier, identifier) when is_binary(refresh_identifier) do
    case Redis.command(["SET", "refresh_session:#{refresh_identifier}", identifier, "NX", "EX", @refresh_expiration]) do
      {:ok, _} ->
        {:ok, :stored_session}
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec delete_refresh_session(binary()) ::
    {:ok, :deleted_session} | {:error, :internal_server_error}
  defp delete_refresh_session(refresh_identifier) when is_binary(refresh_identifier) do
    case Redis.command(["GETDEL", "refresh_session:#{refresh_identifier}"]) do
      {:ok, payload} when not is_nil(payload) ->
        {:ok, :deleted_session}
      _ ->
        {:error, :internal_server_error}
    end
  end
end
