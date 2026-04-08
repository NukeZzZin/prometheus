defmodule Prometheus.Contexts.PostContextTest do
  use Prometheus.Test.DataCase, async: true
  alias Prometheus.Contexts.PostContext
  alias Prometheus.Schemas.PostSchema

  @valid_attributes %{"title" => "Test Post", "content" => "Test Post Content."}

  setup do: inject_mocking_user()

  describe "create_post/1" do
    test "successfully creates a post and returns the post_id", %{author_id: author_id} do
      assert {:ok, %{post_id: post_id}} = PostContext.create_post(Map.put(@valid_attributes, "author_id", author_id))
      assert is_binary(post_id)
      post = Repository.get(PostSchema, post_id)
      assert post.title == "Test Post"
    end

    test "returns error changeset when author_id does not exist" do
      assert {:error, %Ecto.Changeset{} = changeset} = PostContext.create_post(Map.put(@valid_attributes, "author_id", "1"))
      assert "does not exist" in errors_on(changeset).author_id
    end
  end

  describe "get_post_by_identifier/1" do
    test "returns the post when it exists", %{author_id: author_id} do
      {:ok, %{post_id: post_id}} = PostContext.create_post(Map.put(@valid_attributes, "author_id", author_id))
      assert {:ok, %PostSchema{id: ^post_id, title: "Test Post"}} = PostContext.get_post_by_identifier(post_id)
    end

    test "returns {:error, :not_found} when post does not exist" do
      assert {:error, :not_found} = PostContext.get_post_by_identifier("not-post-id")
    end
  end

  describe "list_recent_posts/1" do
    test "returns posts ordered by most recent", %{author_id: author_id} do
      {:ok, %{post_id: _not_listed_post_id}} = PostContext.create_post(Map.put(@valid_attributes, "author_id", author_id) |> Map.put("title", "Test Post 1"))
      {:ok, %{post_id: listed_post_id_1}} = PostContext.create_post(Map.put(@valid_attributes, "author_id", author_id) |> Map.put("title", "Test Post 2"))
      {:ok, %{post_id: listed_post_id_2}} = PostContext.create_post(Map.put(@valid_attributes, "author_id", author_id) |> Map.put("title", "Test Post 3"))
      assert {:ok, posts_list} = PostContext.list_recent_posts(2)
      assert length(posts_list) == 2
      [listed_post_1, listed_post_2] = posts_list
      assert listed_post_1.id == listed_post_id_2 and listed_post_2.id == listed_post_id_1
    end
  end

  describe "list_posts_by_author/2" do
    test "filters posts by author_id", %{author_id: author_id} do
      PostContext.create_post(Map.put(@valid_attributes, "author_id", author_id))
      assert {:ok, posts_list} = PostContext.list_posts_by_author(author_id)
      assert length(posts_list) == 1 and hd(posts_list).author_id == author_id
    end

    test "returns empty list if author has no posts" do
      assert {:ok, []} = PostContext.list_posts_by_author("not_post_author")
    end
  end
end
