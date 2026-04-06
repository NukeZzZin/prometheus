defmodule Prometheus.Contexts.PostContext do
  import Ecto.Query
  alias Prometheus.Repository
  alias Prometheus.Schemas.PostSchema

  @spec create_post(map()) :: {:ok, %{post_id: String.t()}} | {:error, Ecto.Changeset.t()} | {:error, :internal_server_error}
  def create_post(%{"title" => _, "content" => _, "author_id" => _} = attributes) do
    case Repository.insert(PostSchema.create_post_changeset(%PostSchema{}, attributes)) do
      {:ok, %PostSchema{id: identifier}} -> {:ok, %{post_id: identifier}}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      _ -> {:error, :internal_server_error}
    end
  end

  @spec get_post_by_identifier(String.t()) :: {:ok, PostSchema.t()} | {:error, :not_found}
  def get_post_by_identifier(identifier) do
    repository_query = from subject in PostSchema, where: subject.id == ^identifier
    case Repository.one(repository_query) do
      %PostSchema{} = record -> {:ok, record}
      _ -> {:error, :not_found}
    end
  end

  @spec list_recent_posts(pos_integer()) :: {:ok, [PostSchema.t()]}
  def list_recent_posts(limit \\ 10) do
    repository_query = from subject in PostSchema, order_by: [desc: subject.inserted_at], limit: ^limit
    {:ok, Repository.all(repository_query)}
  end

  @spec list_posts_by_author(String.t(), pos_integer()) :: {:ok, [PostSchema.t()]}
  def list_posts_by_author(author_id, limit \\ 10) do
    repository_query = from subject in PostSchema, where: subject.author_id == ^author_id, order_by: [desc: subject.inserted_at], limit: ^limit
    {:ok, Repository.all(repository_query)}
  end
end
