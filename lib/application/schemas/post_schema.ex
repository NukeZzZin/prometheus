defmodule Prometheus.Schemas.PostSchema do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, only: [:id, :title, :content, :author_id]}

  @type t :: %__MODULE__{}

  schema "posts" do
    field :title, :string
    field :content, :string
    field :author_id, :integer

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

  # * === Helpers === * #
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
