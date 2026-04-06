defmodule PrometheusEntry.Controllers.FallbackController do
  use PrometheusEntry, :controller

  def call(connection, {:error, :bad_request}), do:
    send_resp(connection, :bad_request, Jason.encode!(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid request"}]}))

  def call(connection, {:error, :unauthorized}), do:
    send_resp(connection, :unauthorized, Jason.encode!(%{success: false, errors: [%{code: "UNAUTHORIZED", message: "Unauthorized"}]}))

  def call(connection, {:error, :not_found}), do:
    send_resp(connection, :not_found, Jason.encode!(%{success: false, errors: [%{code: "NOT_FOUND", message: "Resource Not found"}]}))

  def call(connection, {:error, :forbidden}), do:
    send_resp(connection, :forbidden, Jason.encode!(%{success: false, errors: [%{code: "FORBIDDEN", message: "Forbidden"}]}))

  def call(connection, {:error, :invalid_credentials}), do:
    send_resp(connection, :unauthorized, Jason.encode!(%{success: false, errors: [%{code: "INVALID_CREDENTIALS", message: "Invalid credentials"}]}))

  def call(connection, {:error, %Ecto.Changeset{} = changeset}), do:
    send_resp(connection, :unprocessable_content, Jason.encode!(%{success: false, errors: format_changeset_errors(changeset)}))

  def call(connection, {:error, _reason}), do:
    send_resp(connection, :internal_server_error, Jason.encode!(%{success: false, errors: [%{code: "INTERNAL_SERVER_ERROR", message: "Unexpected error"}]}))

  # === Private Helpers === #
  @spec format_changeset_errors(Ecto.Changeset.t()) :: [%{field: atom(), code: String.t(), message: String.t()}]
  defp format_changeset_errors(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, options} ->
      Enum.reduce(options, message, fn {key, value}, interpolated_message ->
        String.replace(interpolated_message, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        %{field: field, code: "INVALID_FIELD", message: message}
      end)
    end)
  end
end
