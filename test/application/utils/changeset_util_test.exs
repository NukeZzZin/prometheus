defmodule Prometheus.Utils.ChangesetUtilTest do
  use Prometheus.Test.DataCase, async: true
  alias Prometheus.Utils.ChangesetUtil

  @types %{id: :string, name: :string}

  describe "put_changeset_snowflake_id/1" do
    test "adds a snowflake id when id is nil" do
      changeset = cast({%{}, @types}, %{}, [])
      updated_changeset = ChangesetUtil.put_changeset_snowflake_id(changeset)
      snowflake_id = get_change(updated_changeset, :id)
      assert is_binary(snowflake_id) and String.match?(snowflake_id, ~r/^\d+$/)
    end

    test "does not overwrite an existing id in the underlying data" do
      changeset = cast({%{id: "existing_id"}, @types}, %{}, [])
      updated_changeset = ChangesetUtil.put_changeset_snowflake_id(changeset)
      refute Map.has_key?(updated_changeset.changes, :id)
      assert get_field(updated_changeset, :id) == "existing_id"
    end
  end

  describe "put_normalized_field/2" do
    test "normalizes a string field" do
      changeset = cast({%{}, @types}, %{name: "  ELIXIR  "}, [:name])
      updated_changeset = ChangesetUtil.put_normalized_field(changeset, :name)
      assert get_change(updated_changeset, :name) == "elixir"
    end

    test "raises error if the field value is not a binary" do
      changeset = change({%{}, @types}, %{name: 123})
      assert_raise FunctionClauseError, fn -> ChangesetUtil.put_normalized_field(changeset, :name) end
    end
  end
end
