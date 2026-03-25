defmodule PrometheusEntry.Controllers.AccountController do
  use PrometheusEntry, :controller

  alias Prometheus.Contexts.AccountContext

  @spec register(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def register(connection, parameters) when is_map(parameters) and map_size(parameters) > 0 do
    if connection.assigns[:current_user] != nil do
      connection
      |> put_status(:forbidden)
      |> json(%{success: false, errors: [%{code: "FORBIDDEN", message: "You are already logged in"}]})
    else
      case AccountContext.register_user(parameters) do
        {:ok, tuple_tokens} ->
          connection
          |> put_status(:created)
          |> json(%{success: true, data: tuple_tokens})
        {:error, %Ecto.Changeset{} = changeset} ->
          connection
          |> put_status(:unprocessable_entity)
          |> json(%{success: false, errors: format_changeset_errors(changeset)})
        _ ->
          connection
          |> put_status(:internal_server_error)
          |> json(%{success: false, errors: [%{code: "INTERNAL_SERVER_ERROR", message: "Unexpected error"}]})
      end
    end
  end

  def register(connection, _invalid), do:
    connection
    |> put_status(:bad_request)
    |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]})

  @spec login(Plug.Conn.t(), %{identifier: String.t(), password: String.t()}) :: Plug.Conn.t()
  def login(connection, %{"identifier" => identifier, "password" => password}) when is_binary(identifier) and is_binary(password) do
    if connection.assigns[:current_user] != nil do
      connection
      |> put_status(:forbidden)
      |> json(%{success: false, errors: [%{code: "FORBIDDEN", message: "You are already logged in"}]})
    else
      case AccountContext.login_user(identifier, password) do
        {:ok, tuple_tokens} ->
          connection
          |> put_status(:ok)
          |> json(%{success: true, data: tuple_tokens})
        _ ->
          connection
          |> put_status(:unauthorized)
          |> json(%{success: false, errors: [%{code: "INVALID_CREDENTIALS", message: "Invalid credentials"}]})
      end
    end
  end

  def login(connection, _invalid), do:
    connection
    |> put_status(:bad_request)
    |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]})

  # ! === Private Helpers === ! #
  @spec format_changeset_errors(Ecto.Changeset.t()) ::
    [%{field: atom(), code: String.t(), message: String.t()}]
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
      Enum.reduce(options, message, fn {key, value}, callback ->
        String.replace(callback, "%{#{key}}", inspect(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        %{field: field, code: "CHANGESET_ERROR", message: message}
      end)
    end)
  end
end
