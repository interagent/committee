# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator do
  it "parses simple content types" do
    request = Rack::Request.new({ "CONTENT_TYPE" => "application/json" })
    media_type = Committee::SchemaValidator.request_media_type(request)
    assert_equal 'application/json', media_type
  end

  it "parses comma-delineated content types" do
    request = Rack::Request.new({ "CONTENT_TYPE" => "multipart/form-data, application/json" })
    media_type = Committee::SchemaValidator.request_media_type(request)
    assert_equal 'multipart/form-data', media_type
  end

  it "parses semicolon-delineated content types" do
    request = Rack::Request.new({ "CONTENT_TYPE" => "multipart/form-data; application/json" })
    media_type = Committee::SchemaValidator.request_media_type(request)
    assert_equal 'multipart/form-data', media_type
  end

  it "detects application/json as a JSON media type" do
    assert_equal true, Committee::SchemaValidator.json_media_type?("application/json")
  end

  it "detects application/problem+json with parameters as a JSON media type" do
    assert_equal true, Committee::SchemaValidator.json_media_type?("application/problem+json; charset=utf-8")
  end

  it "detects application/vnd.api+json as a JSON media type" do
    assert_equal true, Committee::SchemaValidator.json_media_type?("application/vnd.api+json")
  end

  it "does not detect application/x-ndjson as a JSON media type" do
    assert_equal false, Committee::SchemaValidator.json_media_type?("application/x-ndjson")
  end

  it "does not detect non-JSON content types as JSON media types" do
    assert_equal false, Committee::SchemaValidator.json_media_type?("test/csv")
    assert_equal false, Committee::SchemaValidator.json_media_type?(nil)
  end

  it "parses +json responses in the HyperSchema validator" do
    schema = Committee::Drivers::OpenAPI2::Driver.new.parse(open_api_2_data)
    validator_option = Committee::SchemaValidator::Option.new({ parse_response_by_content_type: true }, schema, :hyper_schema)
    router = Committee::SchemaValidator::HyperSchema::Router.new(schema, validator_option)
    request = Rack::Request.new({ "REQUEST_METHOD" => "GET", "PATH_INFO" => "/api/pets", "rack.input" => StringIO.new("") })
    validator = Committee::SchemaValidator::HyperSchema.new(router, request, validator_option)

    validator.link.media_type = "application/vnd.api+json"

    validator.response_validate(200, { "Content-Type" => "application/vnd.api+json" }, [JSON.generate([ValidPet])])
  end

  it "builds prefix regexp with a path segment boundary" do
    regexp = Committee::SchemaValidator.build_prefix_regexp("/v1")

    assert regexp.match?("/v1")
    assert regexp.match?("/v1/characters")
    refute regexp.match?("/v11/characters")
  end
end
