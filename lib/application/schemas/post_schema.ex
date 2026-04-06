defmodule Prometheus.Schemas.PostSchema do
  use Ecto.Schema
  import Ecto.Changeset
  alias Prometheus.Utils.SnowflakeUtil

  @primary_key {:id, :string, autogenerate: false}
  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, only: [:id, :title, :content, :author_id]}

  @type t :: %__MODULE__{}

  schema "posts" do
    field :title, :string
    field :content, :string
    belongs_to :author, Prometheus.Schemas.UserSchema, foreign_key: :author_id, type: :string
    timestamps()
  end

  @spec create_post_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def create_post_changeset(changeset, attributes) do
    changeset
    |> cast(attributes, [:title, :content, :author_id])
    |> validate_required([:title, :content, :author_id])
    |> SnowflakeUtil.put_changeset_snowflake_id()
  end

  @spec update_post_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def update_post_changeset(changeset, attributes) do
    changeset
    |> cast(attributes, [:title, :content])
    |> validate_required([:title, :content])
  end
end
