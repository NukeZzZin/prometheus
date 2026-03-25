defmodule Prometheus.Schemas.PostSchema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Prometheus.Schemas.UserSchema

  @primary_key {:id, :integer, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]

  @type t :: %__MODULE__{}

  schema "posts" do
    field :title, :string
    field :content, :string

    belongs_to :author, UserSchema, foreign_key: :author_id

    timestamps()
  end

  @spec create_post_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def create_post_changeset(changeset, attributes) do
    changeset
    |> cast(attributes, [:title, :content, :author_id])
    |> validate_required([:title, :content, :author_id])
    |> put_snowflake_id()
  end

  @spec update_post_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def update_post_changeset(changeset, attributes) do
    changeset
    |> cast(attributes, [:title, :content])
    |> validate_required([:title, :content])
  end

  # ! === Private Helpers === ! #
  @spec put_snowflake_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_snowflake_id(%Ecto.Changeset{valid?: true} = changeset) do
    case get_field(changeset, :id) do
      nil ->
        case Snowflake.next_id() do
          {:ok, snowflake} ->
            put_change(changeset, :id, snowflake)
          {:error, :backwards_clock} ->
            add_error(changeset, :id, "failed to generate snowflake id (clock moved backwards)")
        end
      _ ->
        changeset
    end
  end
  defp put_snowflake_id(changeset), do: changeset
end

defimpl Jason.Encoder, for: Prometheus.Schemas.PostSchema do
  @spec encode(Prometheus.Schemas.PostSchema.t(), Jason.Encode.opts()) :: iodata()
  def encode(payload, options) do
    Jason.Encode.map(
      %{
        id: to_string(payload.id),
        title: payload.title,
        content: payload.content,
        author_id: to_string(payload.author_id),
        inserted_at: payload.inserted_at,
        updated_at: payload.updated_at
      },
      options
    )
  end
end
