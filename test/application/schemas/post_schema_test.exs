defmodule Prometheus.Schemas.PostSchemaTest do
  use Prometheus.Test.DataCase, async: true
  alias Prometheus.Schemas.PostSchema

  @valid_attributes %{"title" => "Test Post", "content" => "Test Post Content."}

  setup do: inject_mocking_user()

  describe "create_post_changeset/2" do
    test "changeset with valid attributes is valid", %{author_id: author_id} do
      changeset = PostSchema.create_post_changeset(%PostSchema{}, Map.put(@valid_attributes, "author_id", author_id))
      assert changeset.valid? and changeset.changes.title == "Test Post" and changeset.changes.content == "Test Post Content." and changeset.changes.author_id == author_id
      assert is_binary(get_field(changeset, :id))
    end

    test "changeset is invalid when required fields are missing" do
      changeset = PostSchema.create_post_changeset(%PostSchema{}, %{})
      assert %{title: ["can't be blank"], content: ["can't be blank"], author_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "update_post_changeset/2" do
    test "allows updating title and content but ignores author_id", %{author_id: author_id} do
      post = %PostSchema{title: "Test Post", content: "Test Post Content.", author_id: author_id}
      attributes = %{"title" => "Updated Title", "content" => "Updated Content", "author_id" => "1"}
      changeset = PostSchema.update_post_changeset(post, attributes)
      assert changeset.valid? and get_change(changeset, :title) == "Updated Title" and get_change(changeset, :content) == "Updated Content"
      refute Map.has_key?(changeset.changes, :author_id)
      assert get_field(changeset, :author_id) == author_id
    end

    test "changeset is invalid when required fields are missing" do
      changeset = PostSchema.create_post_changeset(%PostSchema{}, %{})
      assert %{title: ["can't be blank"], content: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
