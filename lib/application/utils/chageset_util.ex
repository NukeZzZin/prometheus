defmodule Prometheus.Utils.ChangesetUtil do
  @moduledoc false
  import Ecto.Changeset
  alias Prometheus.Utils.GenericUtil

  @spec put_changeset_snowflake_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def put_changeset_snowflake_id(%Ecto.Changeset{valid?: true} = changeset) do
    with nil <- get_field(changeset, :id),
      {:ok, snowflake_id} <- Snowflake.next_id() do
        put_change(changeset, :id, Integer.to_string(snowflake_id))
    else
      {:error, :backwards_clock} -> add_error(changeset, :id, "failed to generate snowflake id (clock moved backwards)")
      _ -> changeset
    end
  end
  def put_changeset_snowflake_id(changeset), do: changeset

  @spec put_normalized_field(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def put_normalized_field(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    case get_field(changeset, field) do
      nil -> changeset
      value -> put_change(changeset, field, GenericUtil.normalize_string(value))
    end
  end
end
