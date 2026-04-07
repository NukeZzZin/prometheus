defmodule Prometheus.Contexts.SessionContext do
  @moduledoc false
  alias Prometheus.Redis
  alias Prometheus.Utils.TokenUtil

  @refresh_expiration 604_800 # ! (7*24*60*60=604800) seconds - 7 days

  @spec create_session(String.t()) :: {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, :internal_server_error}
  def create_session(user_id) do
    with {:ok, %{access: {access_token, _}, refresh: {refresh_token, refresh_claims}}} <- TokenUtil.generate_tuple_token(user_id),
      {:ok, :stored_session} <- store_refresh_session(refresh_claims["jti"], refresh_claims["sub"]) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      _ -> {:error, :internal_server_error}
    end
  end

  @spec rotate_session(Joken.bearer_token()) :: {:ok, %{access_token: Joken.bearer_token(), refresh_token: Joken.bearer_token()}} | {:error, :internal_server_error}
  def rotate_session(old_token) do
    with {:ok, old_claims} <- TokenUtil.verify_refresh_token(old_token),
      {:ok, :revoked_session} <- delete_refresh_session(old_claims["jti"]),
      {:ok, %{access: {access_token, _}, refresh: {refresh_token, refresh_claims}}} <- TokenUtil.generate_tuple_token(old_claims["sub"]),
      {:ok, :stored_session} <- store_refresh_session(refresh_claims["jti"], refresh_claims["sub"]) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token}}
    else
      _ -> {:error, :internal_server_error}
    end
  end

  @spec revoke_session(Joken.bearer_token()) :: {:ok, :revoked_session} | {:error, :internal_server_error}
  def revoke_session(refresh_token) do
    case TokenUtil.verify_refresh_token(refresh_token) do
      {:ok, refresh_claims} -> delete_refresh_session(refresh_claims["jti"])
      _ -> {:error, :internal_server_error}
    end
  end

  # * === Private Helpers === * #
  @spec store_refresh_session(String.t(), String.t()) :: {:ok, :stored_session} | {:error, :internal_server_error}
  defp store_refresh_session(identifier, subject) do
    case Redis.command(["SET", "refresh_session:#{identifier}", subject, "NX", "EX", @refresh_expiration]) do
      {:ok, "OK"} -> {:ok, :stored_session}
      _ -> {:error, :internal_server_error}
    end
  end

  @spec delete_refresh_session(String.t()) :: {:ok, :revoked_session} | {:error, :internal_server_error}
  defp delete_refresh_session(identifier) do
    case Redis.command(["GETDEL", "refresh_session:#{identifier}"]) do
      {:ok, nil} -> {:error, :internal_server_error}
      {:ok, _} -> {:ok, :revoked_session}
      _ -> {:error, :internal_server_error}
    end
  end
end
