defmodule Prometheus.Utils.TokenUtil do
  @moduledoc false
  use Joken.Config

  @issuer "Prometheus-Backend"
  @audience "Prometheus-Frontend"

  @access_expiration 900 # ! (15*60=900) seconds - 15 minutes
  @refresh_expiration 604_800 # ! (7*24*60*60=604800) seconds - 7 days
  @clock_skew 15 # ! clock skew tolerance in seconds

  @impl Joken.Config
  def token_config do
    default_claims(skip: [:aud, :iss])
    |> add_claim("iss", fn -> @issuer end, &(&1 == @issuer))
    |> add_claim("aud", fn -> @audience end, &(&1 == @audience))
    |> add_claim("sub", nil, &is_binary/1)
    |> add_claim("typ", nil, &(&1 in ["access", "refresh"]))
    |> add_claim("jti", nil, &is_binary/1)
    |> add_claim("exp", nil, fn exp ->
      is_integer(exp) and exp > Joken.current_time() - @clock_skew
    end)
    |> add_claim("nbf", nil, fn nbf ->
      is_integer(nbf) and nbf <= Joken.current_time() + @clock_skew
    end)
  end

  @spec generate_tuple_token(String.t()) :: {:ok, %{access: {Joken.bearer_token(), Joken.claims()}, refresh: {Joken.bearer_token(), Joken.claims()}}} | {:error, :internal_server_error}
  def generate_tuple_token(user_id) do
    with {:ok, access_token, access_claims} <- generate_access_token(user_id),
      {:ok, refresh_token, refresh_claims} <- generate_refresh_token(user_id) do
        {:ok, %{access: {access_token, access_claims}, refresh: {refresh_token, refresh_claims}}}
    else
      _ -> {:error, :internal_server_error}
    end
  end

  @spec generate_access_token(String.t()) :: {:ok, Joken.bearer_token(), Joken.claims()} | {:error, :internal_server_error}
  def generate_access_token(subject), do: generate_generic_token(subject, "access", @access_expiration)

  @spec generate_refresh_token(String.t()) :: {:ok, Joken.bearer_token(), Joken.claims()} | {:error, :internal_server_error}
  def generate_refresh_token(subject), do: generate_generic_token(subject, "refresh", @refresh_expiration)

  @spec verify_access_token(Joken.bearer_token()) :: {:ok, Joken.claims()} | {:error, :invalid_token}
  def verify_access_token(payload), do: verify_generic_token(payload, "access")

  @spec verify_refresh_token(Joken.bearer_token()) :: {:ok, Joken.claims()} | {:error, :invalid_token}
  def verify_refresh_token(payload), do: verify_generic_token(payload, "refresh")

  # * === Private Helpers === * #
  @spec verify_generic_token(Joken.bearer_token(), String.t()) :: {:ok, Joken.claims()} | {:error, :invalid_token}
  defp verify_generic_token(payload, expected_type) do
    case verify_and_validate(payload) do
      {:ok, %{"typ" => ^expected_type} = claims} -> {:ok, claims}
      _ -> {:error, :invalid_token}
    end
  end

  @spec generate_generic_token(String.t(), String.t(), pos_integer()) :: {:ok, Joken.bearer_token(), Joken.claims()} | {:error, :internal_server_error}
  defp generate_generic_token(subject, claims_type, expiration) do
    current_time = Joken.current_time()
    generic_claims = %{"sub" => subject, "typ" => claims_type, "jti" => Joken.generate_jti(), "exp" => current_time + expiration, "nbf" => current_time}
    case generate_and_sign(generic_claims) do
      {:ok, bearer_token, claims} -> {:ok, bearer_token, claims}
      {:error, _} -> {:error, :internal_server_error}
    end
  end
end
