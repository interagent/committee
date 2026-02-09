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

  it "builds prefix regexp with a path segment boundary" do
    regexp = Committee::SchemaValidator.build_prefix_regexp("/v1")

    assert regexp.match?("/v1")
    assert regexp.match?("/v1/characters")
    refute regexp.match?("/v11/characters")
  end
end
