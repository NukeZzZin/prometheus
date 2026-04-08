defmodule Prometheus.Schemas.UserSchemaTest do
  use Prometheus.Test.DataCase, async: true
  alias Prometheus.Schemas.UserSchema

  @valid_attributes %{"username" => "test_user", "display_name" => "Test User", "email" => "test@test.test", "password" => "TestP@ssw0rd"}

  describe "create_user_changeset/2" do
    test "changeset with valid attributes is valid" do
      changeset = UserSchema.create_user_changeset(%UserSchema{}, @valid_attributes)
      assert changeset.valid? and changeset.changes.username == "test_user"
      assert is_binary(get_field(changeset, :id)) and is_binary(changeset.changes.password_hash)
      assert get_change(changeset, :password_hash) != @valid_attributes["password"]
    end

    test "changeset is invalid when required fields are missing" do
      changeset = UserSchema.create_user_changeset(%UserSchema{}, %{})
      assert %{username: ["can't be blank"], display_name: ["can't be blank"], email: ["can't be blank"], password: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates username format and length" do
      attributes = Map.put(@valid_attributes, "username", "abc")
      changeset = UserSchema.create_user_changeset(%UserSchema{}, attributes)
      assert "username must be between 4 and 32 characters" in errors_on(changeset).username
      attributes = Map.put(@valid_attributes, "username", "Invalid Username!")
      changeset = UserSchema.create_user_changeset(%UserSchema{}, attributes)
      assert "invalid username format" in errors_on(changeset).username
    end

    test "validates email format" do
      attributes = Map.put(@valid_attributes, "email", "email_invalido.com")
      changeset = UserSchema.create_user_changeset(%UserSchema{}, attributes)
      assert "invalid email format" in errors_on(changeset).email
    end

    test "validates password complexity (regex)" do
      attributes = Map.put(@valid_attributes, "password", "weakpassword")
      changeset = UserSchema.create_user_changeset(%UserSchema{}, attributes)
      assert "invalid password format" in errors_on(changeset).password
    end

    test "normalizes email and username" do
      attributes = Map.merge(@valid_attributes, %{"email" => "TESTE@Email.Com ", "username" => "USER_Test"})
      changeset = UserSchema.create_user_changeset(%UserSchema{}, attributes)
      assert get_field(changeset, :email) == "teste@email.com" and get_field(changeset, :username) == "user_test"
    end
  end

  describe "update_profile_changeset/2" do
    test "validates only profile fields and ignores password" do
      user = %UserSchema{username: "old", email: "old@test.com", display_name: "Old"}
      attributes = %{"username" => "new_user", "password" => "N3w_P@ssword_Test"}
      changeset = UserSchema.update_profile_changeset(user, attributes)
      assert changeset.valid? and get_change(changeset, :username) == "new_user"
      refute Map.has_key?(changeset.changes, :password) and Map.has_key?(changeset.changes, :password_hash)
    end
  end

  describe "change_password_changeset/2" do
    test "updates password and generates new hash" do
      user = %UserSchema{password_hash: "antigo_hash"}
      changeset = UserSchema.change_password_changeset(user, %{"password" => "N3w_P@ssword_Test"})
      assert changeset.valid? and changeset.changes.password_hash
      assert Argon2.verify_pass("N3w_P@ssword_Test", changeset.changes.password_hash)
    end
  end
end
