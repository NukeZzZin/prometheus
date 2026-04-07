defmodule PrometheusEntry.Controllers.PostController do
  @moduledoc false
  use PrometheusEntry, :controller
  alias Prometheus.Contexts.PostContext
  alias Prometheus.Utils.GenericUtil
  action_fallback PrometheusEntry.Controllers.FallbackController

  @spec list_posts(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_posts(connection, %{"limit" => limit}) do
    parsed_limit = GenericUtil.parse_integer(limit)
    with {:ok, posts} <- PostContext.list_recent_posts(parsed_limit) do
      connection
      |> put_status(:ok)
      |> json(%{success: true, data: posts})
    end
  end
  def list_posts(connection, _parameters), do: list_posts(connection, %{"limit" => "10"})

  @spec list_user_posts(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_user_posts(connection, %{"id" => user_id, "limit" => limit}) do
    parsed_limit = GenericUtil.parse_integer(limit)
    with {:ok, posts} <- PostContext.list_posts_by_author(user_id, parsed_limit) do
      connection
      |> put_status(:ok)
      |> json(%{success: true, data: posts})
    end
  end
  def list_user_posts(connection, %{"id" => user_id}), do: list_user_posts(connection, %{"id" => user_id, "limit" => "10"})
  def list_user_posts(_connection, _parameters), do: {:error, :bad_request}

  @spec get_post(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_post(connection, %{"id" => post_id}) do
    case PostContext.get_post_by_identifier(post_id) do
      {:ok, post} ->
        connection
        |> put_status(:ok)
        |> json(%{success: true, data: post})
      {:error, :not_found} -> {:error, :not_found}
    end
  end
  def get_post(_connection, _parameters), do: {:error, :bad_request}

  @spec create_post(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_post(connection, %{"title" => _, "content" => _} = parameters) do
    payload = Map.put(parameters, "author_id", connection.assigns[:current_user]["sub"])
    case PostContext.create_post(payload) do
      {:ok, post_id} ->
        connection
        |> put_status(:created)
        |> json(%{success: true, data: post_id})
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      _ -> {:error, :internal_server_error}
    end
  end
  def create_post(_connection, _parameters), do: {:error, :bad_request}
end
