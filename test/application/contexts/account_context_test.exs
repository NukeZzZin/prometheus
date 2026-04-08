defmodule Prometheus.Contexts.AccountContextTest do
  use Prometheus.Test.DataCase, async: true
  alias Prometheus.Contexts.AccountContext
  alias Prometheus.Schemas.UserSchema

  @valid_attributes %{"username" => "test_user", "display_name" => "Test User", "email" => "test@test.test", "password" => "TestP@ssw0rd"}
  @invalid_attributes %{"username" => "not_test_user", "display_name" => "Not Test User", "email" => "not-an-email", "password" => "TestP@ssw0rd"}

  describe "register_user/1" do
    test "successfully registers a user and returns session tokens" do
      assert {:ok, tuple_tokens} = AccountContext.register_user(@valid_attributes)
      assert Map.has_key?(tuple_tokens, :access_token) and Map.has_key?(tuple_tokens, :refresh_token)
      assert Repository.get_by(UserSchema, username: "test_user")
    end

    test "returns error changeset when attributes are invalid" do
      assert {:error, %Ecto.Changeset{} = changeset} = AccountContext.register_user(@invalid_attributes)
      assert "invalid email format" in errors_on(changeset).email
    end
  end

  describe "login_user/1" do
    setup do: AccountContext.register_user(@valid_attributes)

    test "successfully logs in with email" do
      assert {:ok, %{access_token: _, refresh_token: _}} = AccountContext.login_user(%{"identifier" => "test@test.test", "password" => "TestP@ssw0rd"})
    end

    test "successfully logs in with username" do
      assert {:ok, %{access_token: _, refresh_token: _}} = AccountContext.login_user(%{"identifier" => "test_user", "password" => "TestP@ssw0rd"})
    end

    test "fails with incorrect password" do
      assert {:error, :invalid_credentials} = AccountContext.login_user(%{"identifier" => "test_user", "password" => "wrong_password"})
    end

    test "fails with non-existent user (and prevents timing attacks)" do
      assert {:error, :invalid_credentials} = AccountContext.login_user(%{"identifier" => "not_test_user", "password" => "TestP@ssw0rd"})
    end
  end

  describe "get_user_by_identifier/1" do
    test "finds user by email (normalized)" do
      {:ok, _tuple_tokens} = AccountContext.register_user(@valid_attributes)
      assert {:ok, %UserSchema{username: "test_user"}} = AccountContext.get_user_by_identifier("test@test.test")
    end

    test "finds user by username (normalized)" do
      {:ok, _tuple_tokens} = AccountContext.register_user(@valid_attributes)
      assert {:ok, %UserSchema{email: "test@test.test"}} = AccountContext.get_user_by_identifier("test_user")
    end

    test "returns error when user is not found" do
      assert {:error, :not_found} = AccountContext.get_user_by_identifier("not_test_user")
    end
  end
end
