defmodule PrometheusEntry.Controllers.ErrorJSON do
  @moduledoc false
  use PrometheusEntry, :controller

  @spec render(String.t(), map()) :: map()
  def render(template, _assigns), do: build_error_response(extract_status_code(template), Phoenix.Controller.status_message_from_template(template))

  # * === Private Helpers === * #
  @spec extract_status_code(String.t()) :: atom()
  defp extract_status_code(template), do: template |> String.split(".") |> List.first() |> String.to_integer() |> status_atom()

  @spec status_atom(integer()) :: atom()
  defp status_atom(400), do: :bad_request
  defp status_atom(401), do: :unauthorized
  defp status_atom(403), do: :forbidden
  defp status_atom(404), do: :not_found
  defp status_atom(422), do: :unprocessable_content
  defp status_atom(500), do: :internal_server_error
  defp status_atom(_), do: :internal_server_error

  @spec build_error_response(atom(), String.t()) :: map()
  defp build_error_response(code, message), do: %{success: false, errors: [%{code: String.upcase(to_string(code)), message: message}]}
end
