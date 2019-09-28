# frozen_string_literal: true

require "test_helper"

describe Committee::Drivers::OpenAPI2::ParameterSchemaBuilder do
  before do
  end

  it "reflects a basic type into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "limit",
          "type" => "integer",
        }
      ]
    }
    schema, schema_data = call(data)

    assert_nil schema_data
    assert_equal ["limit"], schema.properties.keys
    assert_equal [], schema.required
    assert_equal ["integer"], schema.properties["limit"].type
    assert_nil schema.properties["limit"].enum
    assert_nil schema.properties["limit"].format
    assert_nil schema.properties["limit"].pattern
    assert_nil schema.properties["limit"].min_length
    assert_nil schema.properties["limit"].max_length
    assert_nil schema.properties["limit"].min_items
    assert_nil schema.properties["limit"].max_items
    assert_nil schema.properties["limit"].unique_items
    assert_nil schema.properties["limit"].min
    assert_nil schema.properties["limit"].min_exclusive
    assert_nil schema.properties["limit"].max
    assert_nil schema.properties["limit"].max_exclusive
    assert_nil schema.properties["limit"].multiple_of
  end

  it "reflects a required property into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "limit",
          "required" => true,
        }
      ]
    }
    schema, schema_data = call(data)

    assert_nil schema_data
    assert_equal ["limit"], schema.required
  end

  it "reflects an array with an items schema into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "tags",
          "type" => "array",
          "minItems" => 1,
          "maxItems" => 10,
          "uniqueItems" => true,
          "items" => {
            "type" => "string"
          }
        }
      ]
    }
    schema, schema_data = call(data)

    assert_nil schema_data
    assert_equal ["array"], schema.properties["tags"].type
    assert_equal 1, schema.properties["tags"].min_items
    assert_equal 10, schema.properties["tags"].max_items
    assert_equal true, schema.properties["tags"].unique_items
    assert_equal({ "type" => "string" }, schema.properties["tags"].items)
  end

  it "reflects a enum property into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "type",
          "type" => "string",
          "enum" => ["hoge", "fuga"]
        }
      ]
    }
    schema, schema_data = call(data)

    assert_nil schema_data
    assert_equal ["hoge", "fuga"], schema.properties["type"].enum
  end

  it "reflects string properties into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "password",
          "type" => "string",
          "format" => "password",
          "pattern" => "[a-zA-Z0-9]+",
          "minLength" => 6,
          "maxLength" => 30
        }
      ]
    }
    schema, schema_data = call(data)

    assert_nil schema_data
    assert_equal "password", schema.properties["password"].format
    assert_equal Regexp.new("[a-zA-Z0-9]+"), schema.properties["password"].pattern
    assert_equal 6, schema.properties["password"].min_length
    assert_equal 30, schema.properties["password"].max_length
  end

  it "reflects number properties into a schema" do
    data = {
      "parameters" => [
        {
          "name" => "limit",
          "type" => "integer",
          "minimum" => 20,
          "exclusiveMinimum" => true,
          "maximum" => 100,
          "exclusiveMaximum" => false,
          "multipleOf" => 10
        }
      ]
    }
    schema, schema_data = call(data)

    assert_nil schema_data
    assert_equal 20, schema.properties["limit"].min
    assert_equal true, schema.properties["limit"].min_exclusive
    assert_equal 100, schema.properties["limit"].max
    assert_equal false, schema.properties["limit"].max_exclusive
    assert_equal 10, schema.properties["limit"].multiple_of
  end

  it "returns schema data for a body parameter" do
    data = {
      "parameters" => [
        {
          "name" => "payload",
          "in" => "body",
          "schema" => {
            "$ref" => "#/definitions/foo",
          }
        }
      ]
    }
    schema, schema_data = call(data)

    assert_nil schema
    assert_equal({ "$ref" => "#/definitions/foo" }, schema_data)
  end

  it "requires that certain fields are present" do
    data = {
      "parameters" => [
        {
        }
      ]
    }
    e = assert_raises ArgumentError do
      call(data)
    end
    assert_equal "Committee: no name section in link data.", e.message
  end

  it "requires that body parameters not be mixed with form parameters" do
    data = {
      "parameters" => [
        {
          "name" => "payload",
          "in" => "body",
        },
        {
          "name" => "limit",
          "in" => "form",
        },
      ]
    }
    e = assert_raises ArgumentError do
      call(data)
    end
    assert_equal "Committee: can't mix body parameter with form parameters.",
      e.message
  end

  def call(data)
    Committee::Drivers::OpenAPI2::ParameterSchemaBuilder.new(data).call
  end
end
