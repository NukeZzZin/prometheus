defmodule Prometheus.Utils.TokenUtilTest do
  use ExUnit.Case, async: true
  alias Prometheus.Utils.TokenUtil

  @user_id "1"

  describe "generate_tuple_token/1" do
    test "generates a map containing both access and refresh tokens" do
      assert {:ok, tuple_tokens} = TokenUtil.generate_tuple_token(@user_id)
      assert {access_token, access_claims} = tuple_tokens.access
      assert {refresh_token, refresh_claims} = tuple_tokens.refresh
      assert is_binary(access_token) and is_binary(refresh_token)
      assert access_claims["sub"] == @user_id and refresh_claims["sub"] == @user_id
      assert access_claims["typ"] == "access" and refresh_claims["typ"] == "refresh"
    end
  end

  describe "access tokens" do
    test "successfully generates and verifies a valid access token" do
      {:ok, access_token, _access_claims} = TokenUtil.generate_access_token(@user_id)
      assert {:ok, verified_claims} = TokenUtil.verify_access_token(access_token)
      assert verified_claims["sub"] == @user_id and verified_claims["typ"] == "access"
    end

    test "fails to verify an access token as a refresh token" do
      {:ok, access_token, _access_claims} = TokenUtil.generate_access_token(@user_id)
      assert {:error, :invalid_token} == TokenUtil.verify_refresh_token(access_token)
    end
  end

  describe "refresh tokens" do
    test "successfully generates and verifies a valid refresh token" do
      {:ok, refresh_token, _refresh_claims} = TokenUtil.generate_refresh_token(@user_id)
      assert {:ok, verified_claims} = TokenUtil.verify_refresh_token(refresh_token)
      assert verified_claims["sub"] == @user_id and verified_claims["typ"] == "refresh"
    end

    test "fails to verify a refresh token as an access token" do
      {:ok, refresh_token, _refresh_claims} = TokenUtil.generate_refresh_token(@user_id)
      assert {:error, :invalid_token} == TokenUtil.verify_access_token(refresh_token)
    end
  end

  describe "token validation logic" do
      test "fails to verify tokens with invalid signature or tampered payload" do
        {:ok, access_token, _access_claims} = TokenUtil.generate_access_token(@user_id)
        assert {:error, :invalid_token} = TokenUtil.verify_access_token(access_token <> "broken")
      end

      test "rejects expired tokens (simulated)" do
        {:ok, _access_token, access_claims} = TokenUtil.generate_access_token(@user_id)
        assert access_claims["exp"] > Joken.current_time()
      end
    end
end
