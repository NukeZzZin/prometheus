defmodule Prometheus.Utils.GenericUtilTest do
  use Prometheus.Test.DataCase, async: true
  alias Prometheus.Utils.GenericUtil

  describe "normalize_string/1" do
    test "trims whitespace, converts to lowercase, and normalizes to nfc" do
      assert GenericUtil.normalize_string("  HELLO, WORLD!  ") == "hello, world!"
      assert GenericUtil.normalize_string("\tTEST\n") == "test"
      assert GenericUtil.normalize_string("TéST") == "test"
      assert GenericUtil.normalize_string("ÁÉÍÓÚ") == "aeiou"
      assert GenericUtil.normalize_string("é") == GenericUtil.normalize_string("e\u0301")
    end

    test "raises FunctionClauseError for empty strings or invalid types" do
      assert_raise FunctionClauseError, fn -> GenericUtil.normalize_string("") end
      assert_raise FunctionClauseError, fn -> GenericUtil.normalize_string(nil) end
      assert_raise FunctionClauseError, fn -> GenericUtil.normalize_string(123) end
      assert_raise FunctionClauseError, fn -> GenericUtil.normalize_string([1, 2, 3]) end
    end
  end

  describe "parse_integer/2" do
    test "successfully parses valid numeric strings" do
      assert GenericUtil.parse_integer("42") == 42
      assert GenericUtil.parse_integer("0") == 0
      assert GenericUtil.parse_integer("-10") == -10
      assert GenericUtil.parse_integer("  89  ") == 89
    end

    test "returns default (or nil) for non-numeric strings" do
      assert GenericUtil.parse_integer("abc") == nil
      assert GenericUtil.parse_integer("not_a_number", 5) == 5
    end

    test "returns default for partial numeric strings" do
      assert GenericUtil.parse_integer("100abc") == 100
      assert GenericUtil.parse_integer("12.5") == 12
    end

    test "raises FunctionClauseError for empty strings or invalid types" do
      assert_raise FunctionClauseError, fn -> GenericUtil.parse_integer("") end
      assert_raise FunctionClauseError, fn -> GenericUtil.parse_integer(nil) end
      assert_raise FunctionClauseError, fn -> GenericUtil.normalize_string(123) end
      assert_raise FunctionClauseError, fn -> GenericUtil.normalize_string([1, 2, 3]) end
    end
  end
end
