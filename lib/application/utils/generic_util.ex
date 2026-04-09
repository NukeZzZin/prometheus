defmodule Prometheus.Utils.GenericUtil do
  @moduledoc false
  @spec normalize_string(String.t()) :: String.t()
  def normalize_string(value) when is_binary(value) and byte_size(value) > 0 do
    value
    |> String.trim()
    |> String.downcase(:default)
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
    |> :unicode.characters_to_nfc_binary()
  end

  @spec parse_integer(String.t(), integer() | nil) :: integer() | nil
  def parse_integer(value, default \\ nil) when is_binary(value) and byte_size(value) > 0 do
    trimed_value = String.trim(value)
    case Integer.parse(trimed_value) do
      {parsed_value, _} -> parsed_value
      _ -> default
    end
  end
end
