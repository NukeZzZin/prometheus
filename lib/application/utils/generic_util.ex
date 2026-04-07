defmodule Prometheus.Utils.GenericUtil do
  @moduledoc false
  @spec normalize_string(String.t()) :: String.t()
  def normalize_string(value) when is_binary(value) and byte_size(value) > 0 do
    value
    |> String.trim()
    |> String.downcase(:default)
    |> String.normalize(:nfc)
  end

  @spec parse_integer(String.t(), integer() | nil) :: integer() | nil
  def parse_integer(value, default \\ nil) when is_binary(value) and byte_size(value) > 0 do
    case Integer.parse(value) do
      {parsed_value, ""} -> parsed_value
      _ -> default
    end
  end
end
