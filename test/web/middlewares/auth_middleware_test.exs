defmodule PrometheusEntry.Middlewares.AuthMiddlewareTest do
  use Prometheus.Test.DataCase, async: true
  alias Prometheus.Utils.TokenUtil
  alias PrometheusEntry.Middlewares.AuthMiddleware

  @options AuthMiddleware.init([])

  setup do
    {:ok, access_token, _access_claims} = TokenUtil.generate_access_token("1")
    {:ok, access_token: access_token, user_id: "1"}
  end

  describe "call/2" do
    test "successfully authenticates with a valid bearer token", %{access_token: access_token, user_id: user_id} do
      connection = conn(:get, "/")
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> AuthMiddleware.call(@options)
      assert connection.assigns.current_user["sub"] == user_id
      refute connection.halted
    end

    test "returns 401 unauthorized when token is missing" do
      connection = AuthMiddleware.call(conn(:get, "/"), @options)
      assert connection.status == 401 and connection.halted
      response = Jason.decode!(connection.resp_body)
      assert response["success"] == false and hd(response["errors"])["code"] == "UNAUTHORIZED"
    end

    test "returns 401 unauthorized with malformed header", %{access_token: access_token} do
      connection = conn(:get, "/")
      |> put_req_header("authorization", "NotBearerToken #{access_token}")
      |> AuthMiddleware.call(@options)
      assert connection.status == 401 and connection.halted
    end

    test "returns 401 unauthorized with invalid/expired token" do
      connection = conn(:get, "/")
      |> put_req_header("authorization", "Bearer invalid_or_expired")
      |> AuthMiddleware.call(@options)
      assert connection.status == 401 and connection.halted
    end
  end
end
