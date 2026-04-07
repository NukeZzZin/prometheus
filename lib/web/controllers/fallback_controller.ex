defmodule PrometheusEntry.Controllers.FallbackController do
  use PrometheusEntry, :controller

  def call(connection, {:error, :bad_request}), do: build_response(connection, :bad_request, "Invalid request")
  def call(connection, {:error, :unauthorized}), do: build_response(connection, :unauthorized, "Unauthorized")
  def call(connection, {:error, :forbidden}), do: build_response(connection, :forbidden, "Forbidden")
  def call(connection, {:error, :not_found}), do: build_response(connection, :not_found, "Resource Not found")
  def call(connection, {:error, :invalid_credentials}), do: build_response(connection, :unauthorized, "Invalid credentials")
  def call(connection, {:error, %Ecto.Changeset{} = changeset}), do: build_response(connection, :unprocessable_content, format_changeset_errors(changeset))
  def call(connection, {:error, _reason}), do: build_response(connection, :internal_server_error, "Unexpected error")

  # ! === Private Helpers === ! #
  @spec format_changeset_errors(Ecto.Changeset.t()) :: [%{field: atom(), code: String.t(), message: String.t()}]
  defp format_changeset_errors(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, options} ->
      Enum.reduce(options, message, fn {key, value}, interpolated_message -> String.replace(interpolated_message, "%{#{key}}", to_string(value)) end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message -> %{field: field, code: "INVALID_FIELD", message: message} end)
    end)
  end

  @spec build_response(Plug.Conn.t(), atom(), term()) :: Plug.Conn.t()
  defp build_response(connection, status, data) do
    connection
    |> put_status(status)
    |> json(%{success: false, errors: [%{code: String.upcase(Atom.to_string(status)), message: data}]})
  end
end
