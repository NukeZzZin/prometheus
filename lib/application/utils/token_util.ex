defmodule Prometheus.Utils.TokenUtil do
  use Joken.Config

  @issuer "Prometheus-Backend"
  @audience "Prometheus-Frontend"

  @access_expiration 900 # * (15*60=900) seconds - 15 minutes
  @refresh_expiration 604_800 # * (7*24*60*60=604800) seconds - 7 days
  @clock_skew 15 # * clock skew tolerance in seconds

  @impl Joken.Config
  def token_config do
    with current_time <- Joken.current_time() do
      default_claims()
      |> add_claim("iss", fn -> @issuer end, &(&1 == @issuer))
      |> add_claim("aud", fn -> @audience end, &(&1 == @audience))
      |> add_claim("sub", nil, &is_binary/1)
      |> add_claim("typ", nil, &(&1 in ["access", "refresh"]))
      |> add_claim("jti", nil, &is_binary/1)
      |> add_claim("exp", nil, &(is_integer(&1) and &1 > current_time - @clock_skew))
      |> add_claim("nbf", nil, &(is_integer(&1) and &1 <= current_time + @clock_skew))
    end
  end

  @spec generate_access_token(pos_integer()) ::
    {:ok, Joken.bearer_token(), Joken.claims()} | {:error, :internal_server_error}
  def generate_access_token(subject) when is_integer(subject) do
    with current_time <- Joken.current_time(),
      {:ok, bearer_token, claims} <- generate_and_sign(%{
        "sub" => Integer.to_string(subject),
        "typ" => "access",
        "jti" => Joken.generate_jti(),
        "exp" => current_time + @access_expiration,
        "nbf" => current_time
      }) do
        {:ok, bearer_token, claims}
    else
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec generate_refresh_token(pos_integer()) ::
    {:ok, Joken.bearer_token(), Joken.claims()} | {:error, :internal_server_error}
  def generate_refresh_token(subject) when is_integer(subject) do
    with current_time <- Joken.current_time(),
      {:ok, bearer_token, claims} <- generate_and_sign(%{
        "sub" => Integer.to_string(subject),
        "typ" => "refresh",
        "jti" => Joken.generate_jti(),
        "exp" => current_time + @refresh_expiration,
        "nbf" => current_time
      }) do
        {:ok, bearer_token, claims}
    else
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec generate_tuple_token(pos_integer()) ::
    {:ok, Joken.bearer_token(), Joken.claims(), Joken.bearer_token(), Joken.claims()} | {:error, :internal_server_error}
  def generate_tuple_token(identifier) when is_integer(identifier) do
    with {:ok, access_token, access_claims} <- generate_access_token(identifier),
      {:ok, refresh_token, refresh_claims} <- generate_refresh_token(identifier) do
        {:ok, access_token, access_claims, refresh_token, refresh_claims}
    else
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec verify_access_token(Joken.bearer_token()) ::
    {:ok, Joken.claims()} | {:error, :invalid_access_token}
  def verify_access_token(payload) when is_binary(payload) do
    with {:ok, %{"typ" => "access", "sub" => subject} = claims} <- verify_and_validate(payload),
      {identifier, _} <- Integer.parse(subject) do
        {:ok, Map.put(claims, "sub", identifier)}
    else
      _ -> {:error, :invalid_access_token}
    end
  end

  @spec verify_refresh_token(Joken.bearer_token()) ::
    {:ok, Joken.claims()} | {:error, :invalid_refresh_token}
  def verify_refresh_token(payload) when is_binary(payload) do
    with {:ok, %{"typ" => "refresh", "sub" => subject} = claims} <- verify_and_validate(payload),
      {identifier, _} <- Integer.parse(subject) do
        {:ok, Map.put(claims, "sub", identifier)}
    else
      _ -> {:error, :invalid_refresh_token}
    end
  end
end
