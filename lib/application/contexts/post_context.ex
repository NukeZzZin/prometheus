defmodule Prometheus.Contexts.PostContext do
  import Ecto.Query

  alias Prometheus.Repository
  alias Prometheus.Schemas.PostSchema

  @spec create_post(map())
    :: {:ok, :created_post} | {:error, Ecto.Changeset.t()} | {:error, :internal_server_error}
  def create_post(attributes) when is_map(attributes) and map_size(attributes) > 0 do
    case Repository.insert(PostSchema.create_post_changeset(%PostSchema{}, attributes)) do
      {:ok, %PostSchema{id: identifier}} ->
        {:ok, identifier}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
      _ ->
        {:error, :internal_server_error}
    end
  end

  @spec get_recent_posts(pos_integer()) ::
    {:ok, [PostSchema.t()]} | {:error, :internal_server_error}
  def get_recent_posts(limit \\ 10) when is_integer(limit) and limit > 0 do
    case Repository.all(from subject in PostSchema, order_by: [desc: subject.inserted_at], limit: ^limit) do
      records when is_list(records) ->
        {:ok, records}
      _ ->
        {:error, :internal_server_error}
    end
  end

  # @spec update_post(pos_integer(), map())
  #   :: {:ok, :updated_post} | {:error, Ecto.Changeset.t()} | {:error, :internal_server_error}
  # def update_post(identifier, attributes) when is_integer(identifier) and identifier > 0 and is_map(attributes) and map_size(attributes) > 0 do
  #   with {:ok, %PostSchema{} = post} <- get_post_by_identifier(identifier),
  #     {:ok, _} <- Repository.update(PostSchema.update_post_changeset(post, attributes)) do
  #       {:ok, :updated_post}
  #   else
  #     {:error, :post_not_found} ->
  #       {:error, :post_not_found}
  #     _ ->
  #       {:error, :internal_server_error}
  #   end
  # end

  # @spec delete_post(pos_integer())
  #   :: {:ok, :deleted_post} | {:error, :internal_server_error}
  # def delete_post(identifier) when is_integer(identifier) and identifier > 0 do
  #   with {:ok, %PostSchema{} = post} <- get_post_by_identifier(identifier),
  #     {:ok, _} <- Repository.delete(post) do
  #       {:ok, :deleted_post}
  #   else
  #     {:error, :post_not_found} ->
  #       {:error, :post_not_found}
  #     _ ->
  #       {:error, :internal_server_error}
  #   end
  # end

  # @spec get_post_by_title(String.t()) ::
  #   {:ok, PostSchema.t()} | {:error, :post_not_found}
  # def get_post_by_title(title) when is_binary(title) and byte_size(title) > 0, do:
  #   fetch_post_by_query(from subject in PostSchema, where: subject.title == ^title)

  @spec get_post_by_identifier(pos_integer()) ::
    {:ok, PostSchema.t()} | {:error, :post_not_found}
  def get_post_by_identifier(identifier) when is_integer(identifier) and identifier > 0, do:
    fetch_post_by_query(from subject in PostSchema, where: subject.id == ^identifier)

  # * === Helpers === * #
  @spec fetch_post_by_query(Ecto.Query.t()) ::
    {:ok, PostSchema.t()} | {:error, :post_not_found}
  defp fetch_post_by_query(%Ecto.Query{} = query) do
     case Repository.one(query) do
       %PostSchema{} = record ->
         {:ok, record}
       _ ->
         {:error, :post_not_found}
     end
   end
end
