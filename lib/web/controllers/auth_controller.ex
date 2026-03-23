defmodule PrometheusEntry.Controllers.AuthController do
  use PrometheusEntry, :controller

  alias Prometheus.Contexts.AccountContext

  def register(connection, parameters) when is_map(parameters) and map_size(parameters) > 0 do
    case AccountContext.register_user(parameters) do
      {:ok, tokens} ->
        connection
        |> put_status(:created)
        |> json(%{success: true, data: tokens})
      {:error, %Ecto.Changeset{} = changeset} ->
        connection
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, errors: format_changeset_errors(changeset)})
    end
  end

  def register(connection, _invalid) do
    connection
    |> put_status(:bad_request)
    |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]})
  end

  def login(connection, %{"identifier" => identifier, "password" => password}) do
    case AccountContext.login_user(identifier, password) do
      {:ok, tokens} ->
        connection
        |> put_status(:ok)
        |> json(%{success: true, data: tokens})
      _ ->
        connection
        |> put_status(:unauthorized)
        |> json(%{success: false, errors: [%{code: "INVALID_CREDENTIALS", message: "Invalid credentials"}]})
    end
  end

  def login(connection, _invalid) do
    connection
    |> put_status(:bad_request)
    |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]})
  end

  # * === Helpers === * #
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
      Enum.reduce(options, message, fn {key, value}, callback ->
        String.replace(callback, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        %{field: field, code: "VALIDATION_ERROR", message: message}
      end)
    end)
    |> List.flatten()
  end
end
