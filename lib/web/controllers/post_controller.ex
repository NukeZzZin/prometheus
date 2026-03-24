defmodule PrometheusEntry.Controllers.PostController do
  use PrometheusEntry, :controller

  alias Prometheus.Contexts.PostContext

  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(connection, %{"limit" => limit}) do
    case Integer.parse(limit) do
      {parsed_limit, _} ->
        case PostContext.get_recent_posts(parsed_limit) do
          {:ok, posts} ->
            connection
            |> put_status(:ok)
            |> json(%{success: true, data: posts})
          _ ->
            connection
            |> put_status(:internal_server_error)
            |> json(%{success: false, errors: [%{code: "INTERNAL_SERVER_ERROR", message: "Unexpected error"}]})
        end
      :error ->
        connection
        |> put_status(:bad_request)
        |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid limit parameter"}]})
    end
  end

  def list(connection, _parameters), do:
    list(connection, %{"limit" => "10"})

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(connection, parameters)  when is_map(parameters) and map_size(parameters) > 0 do
    payload = Map.put(parameters, "author_id", connection.assigns[:current_user]["sub"])
    case PostContext.create_post(payload) do
      {:ok, identifier} ->
        connection
        |> put_status(:created)
        |> json(%{success: true, data: %{post_id: identifier}})
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

  def create(connection, _parameters), do:
    send_resp(connection, :bad_request, Jason.encode!(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]}))

    @spec get(Plug.Conn.t(), %{String.t() => String.t()}) :: Plug.Conn.t()
    def get(connection, %{"id" => identifier}) when is_binary(identifier) do
      case Integer.parse(identifier) do
        {parsed_identifier, _} ->
          case PostContext.get_post_by_identifier(parsed_identifier) do
            {:ok, post} ->
              connection
              |> put_status(:ok)
              |> json(%{success: true, data: post})
            {:error, :post_not_found} ->
              connection
              |> put_status(:not_found)
              |> json(%{success: false, errors: [%{code: "NOT_FOUND", message: "Post not found"}]})
          end
        :error ->
          connection
          |> put_status(:bad_request)
          |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid id parameter"}]})
      end
    end

  def get(connection, _parameters), do:
    send_resp(connection, :bad_request, Jason.encode!(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]}))

  # * === Helpers === * #
  @spec format_changeset_errors(Ecto.Changeset.t()) ::
    [%{field: atom(), code: String.t(), message: String.t()}]
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        %{field: field, code: "CHANGESET_ERROR", message: message}
      end)
    end)
  end
end
