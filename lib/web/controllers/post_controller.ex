defmodule PrometheusEntry.Controllers.PostController do
  use PrometheusEntry, :controller

  alias Prometheus.Contexts.PostContext

  @spec list_posts(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_posts(connection, %{"limit" => limit}) do
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
        |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid parameter"}]})
    end
  end

  def list_posts(connection, _parameters), do:
    list_posts(connection, %{"limit" => "10"})

  @spec list_user_posts(Plug.Conn.t(), %{String.t() => String.t()}) :: Plug.Conn.t()
  def list_user_posts(connection, %{"id" => identifier, "limit" => limit}) do
    with {parsed_identifier, _} <- Integer.parse(identifier),
      {parsed_limit, _} <- Integer.parse(limit) do
        case PostContext.get_posts_by_author(parsed_identifier, parsed_limit) do
          {:ok, posts} ->
            connection
            |> put_status(:ok)
            |> json(%{success: true, data: posts})
          {:error, :not_found} ->
            connection
            |> put_status(:not_found)
            |> json(%{success: false, errors: [%{code: "NOT_FOUND", message: "Not found"}]})
        end
      else
        :error ->
          connection
          |> put_status(:bad_request)
          |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid parameter"}]})
      end
    end

  def get_post(connection, %{"id" => identifier}) do
    case Integer.parse(identifier) do
      {parsed_identifier, _} ->
        case PostContext.get_post_by_identifier(parsed_identifier) do
          {:ok, post} ->
            connection
            |> put_status(:ok)
            |> json(%{success: true, data: post})
          {:error, :not_found} ->
            connection
            |> put_status(:not_found)
            |> json(%{success: false, errors: [%{code: "NOT_FOUND", message: "Not found"}]})
        end
      :error ->
        connection
          |> put_status(:bad_request)
          |> json(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid parameter"}]})
    end
  end

  def get_post(connection, _parameters), do:
    send_resp(connection, :bad_request, Jason.encode!(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]}))

  @spec create_post(Plug.Conn.t(), map()) :: Plug.Conn.t()
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

  def create_post(connection, _parameters), do:
    send_resp(connection, :bad_request, Jason.encode!(%{success: false, errors: [%{code: "BAD_REQUEST", message: "Invalid payload"}]}))

  # ! === Private Helpers === ! #
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
