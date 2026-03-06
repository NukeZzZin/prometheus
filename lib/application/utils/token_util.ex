defmodule Prometheus.Utils.TokenUtil do
  use Joken.Config

  @issuer "Prometheus-Backend"
  @audience "Prometheus-Frontend"

  @access_expiration 900 # * (15*60=900) seconds - 15 minutes
  @refresh_expiration 604_800 # * (7*24*60*60=604800) seconds - 7 days
  @clock_skew 15 # * clock skew tolerance in seconds

  @impl Joken.Config
  def token_config do
    with now <- Joken.current_time() do
      default_claims()
      |> add_claim("iss", fn -> @issuer end, &(&1 == @issuer))
      |> add_claim("aud", fn -> @audience end, &(&1 == @audience))
      |> add_claim("sub", nil, &is_binary/1)
      |> add_claim("typ", nil, &(&1 in ["access", "refresh"]))
      |> add_claim("exp", nil, fn (exp) -> (is_integer(exp) and exp + @clock_skew > now) end)
      |> add_claim("nbf", fn -> now end, fn (nbf) -> (is_integer(nbf) and nbf <= now + @clock_skew) end)
    end
  end

  @spec generate_access_token(pos_integer()) :: {:ok, binary(), %{binary() => term()}} | {:error, atom()}
  def generate_access_token(subject) when is_integer(subject) and subject > 0 do
    case generate_and_sign(%{
      "sub" => Integer.to_string(subject),
      "typ" => "access",
      "exp" => Joken.current_time() + @access_expiration
    }) do
      {:ok, bearer_token, claims} ->
        {:ok, bearer_token, claims}
      {:error, _reason} ->
        {:error, :token_generation_failed}
    end
  end

  @spec generate_refresh_token(pos_integer()) :: {:ok, binary(), %{binary() => term()}} | {:error, term()}
  def generate_refresh_token(subject) when is_integer(subject) do
    case generate_and_sign(%{
      "sub" => Integer.to_string(subject),
      "typ" => "refresh",
      "jti" => Joken.generate_jti(),
      "exp" => Joken.current_time() + @refresh_expiration
    }) do
      {:ok, bearer_token, claims} ->
        {:ok, bearer_token, claims}
      {:error, _reason} ->
        {:error, :token_generation_failed}
    end
  end

  @spec generate_tuple_token(pos_integer()) :: {:ok, binary(), %{binary() => term()}, binary(), %{binary() => term()}} | {:error, term()}
  def generate_tuple_token(identifier) when is_integer(identifier) do
    with {:ok, access_token, access_claims} <- generate_access_token(identifier),
      {:ok, refresh_token, refresh_claims} <- generate_refresh_token(identifier) do
        {:ok, access_token, access_claims, refresh_token, refresh_claims}
    else
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec verify_access_token(binary()) :: {:ok, %{binary() => term()}} | {:error, term()}
  def verify_access_token(payload) when is_binary(payload) do
    with {:ok, %{"typ" => "access", "sub" => subject} = claims} <- verify_and_validate(payload),
      {identifier, _} <- Integer.parse(subject) do
        {:ok, Map.put(claims, "sub", identifier)}
    else
      _ -> {:error, :invalid_access_token}
    end
  end

  @spec verify_refresh_token(binary()) ::{:ok, %{binary() => term()}} | {:error, term()}
  def verify_refresh_token(payload) when is_binary(payload) do
    with {:ok, %{"typ" => "refresh", "sub" => subject} = claims} <- verify_and_validate(payload),
      {identifier, _} <- Integer.parse(subject) do
        {:ok, Map.put(claims, "sub", identifier)}
    else
      _ -> {:error, :invalid_refresh_token}
    end
  end
end
