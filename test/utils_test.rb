# frozen_string_literal: true

require "test_helper"

describe Committee::Utils do
  describe ".schema_type" do
    def schema(type)
      Struct.new(:type).new(type)
    end

    it "returns a string type as is" do
      assert_equal "integer", Committee::Utils.schema_type(schema("integer"))
    end

    it "returns the first non-null type of an array-form type" do
      assert_equal "array", Committee::Utils.schema_type(schema(["null", "array"]))
      assert_equal "integer", Committee::Utils.schema_type(schema(["integer", "string"]))
    end

    it "returns nil when only null is listed" do
      assert_nil Committee::Utils.schema_type(schema(["null"]))
    end

    it "returns nil without a schema" do
      assert_nil Committee::Utils.schema_type(nil)
    end
  end
end
