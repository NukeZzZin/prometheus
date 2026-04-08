defmodule Prometheus.Contexts.SessionContextTest do
  use Prometheus.Test.DataCase, async: false
  alias Prometheus.Contexts.SessionContext
  alias Prometheus.Utils.TokenUtil

  @user_id "1"

  describe "create_session/1" do
    test "successfully creates a session and stores it in Redis" do
      assert {:ok, %{access_token: access_token, refresh_token: refresh_token}} = SessionContext.create_session(@user_id)
      assert is_binary(access_token) and is_binary(refresh_token)
      {:ok, refresh_claims} = TokenUtil.verify_refresh_token(refresh_token)
      assert {:ok, @user_id} == Redis.command(["GET", "refresh_session:#{refresh_claims["jti"]}"])
    end
  end

  describe "rotate_session/1" do
    test "revokes old session and creates a new one" do
      {:ok, %{access_token: _old_access_token, refresh_token: old_refresh_token}} = SessionContext.create_session(@user_id)
      {:ok, old_refresh_claims} = TokenUtil.verify_refresh_token(old_refresh_token)
      assert {:ok, %{access_token: _new_access_token, refresh_token: new_refresh_token}} = SessionContext.rotate_session(old_refresh_token)
      assert {:ok, nil} == Redis.command(["GET", "refresh_session:#{old_refresh_claims["jti"]}"])
      {:ok, new_refresh_claims} = TokenUtil.verify_refresh_token(new_refresh_token)
      assert {:ok, @user_id} == Redis.command(["GET", "refresh_session:#{new_refresh_claims["jti"]}"])
      assert new_refresh_token != old_refresh_token
    end

    test "returns error if the token is invalid or already revoked" do
      assert {:error, :internal_server_error} = SessionContext.rotate_session("invalid_token")
    end
  end

  describe "revoke_session/1" do
    test "successfully removes the session from Redis" do
      {:ok, %{access_token: _access_token, refresh_token: refresh_token}} = SessionContext.create_session(@user_id)
      {:ok, refresh_claims} = TokenUtil.verify_refresh_token(refresh_token)
      assert {:ok, :revoked_session} = SessionContext.revoke_session(refresh_token)
      assert {:ok, nil} == Redis.command(["GET", "refresh_session:#{refresh_claims["jti"]}"])
    end

    test "returns error when trying to revoke an already revoked session" do
      {:ok, %{access_token: _access_token, refresh_token: refresh_token}} = SessionContext.create_session(@user_id)
      SessionContext.revoke_session(refresh_token)
      assert {:error, :internal_server_error} = SessionContext.revoke_session(refresh_token)
    end
  end
end
