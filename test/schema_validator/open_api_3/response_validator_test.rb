# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::OpenAPI3::ResponseValidator do
  before do
    @status = 200
    @headers = {
      "Content-Type" => "application/json"
    }
    @data = {"string" => "Honoka.Kousaka"}

    @path = '/validate'
    @method = 'post'

    # TODO: delete when 5.0.0 released because default value changed
    options = {}
    options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil
    
    @validator_option = Committee::SchemaValidator::Option.new(options, open_api_3_schema, :open_api_3)
  end

  it "passes through a valid response" do
    call_response_validator
  end

  it "passes through a valid response with Content-Type options" do
    @headers = { "Content-Type" => "application/json; charset=utf-8" }
    call_response_validator
  end

  it "passes through a valid response with no registered Content-Type with strict = false" do
    @headers = { "Content-Type" => "application/xml" }
    call_response_validator
  end

  it "raises InvalidResponse when a valid response with no registered body with strict option" do
    @headers = { "Content-Type" => "application/xml" }
    e = assert_raises(Committee::InvalidResponse) {
      call_response_validator(true)
    }
    assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
  end

  it "raises InvalidResponse when a invalid status code with strict option" do
    @status = 201
    e = assert_raises(Committee::InvalidResponse) {
      call_response_validator(true)
    }

    assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
  end

  it "passes through a valid response with no Content-Type" do
    @headers = {}
    call_response_validator
  end

  it "raises InvalidResponse when a valid response with no Content-Type headers with strict option" do
    @headers = {}
    e = assert_raises(Committee::InvalidResponse) {
      call_response_validator(true)
    }
    assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
  end

  it "passes through a valid list response" do
    @path = '/validate_response_array'
    @method = 'get'
    @data = ["Mari.Ohara"]
    call_response_validator
  end

  it "passes through a 204 No Content response" do
    @status, @headers, @data = 204, {}, nil
    call_response_validator
  end

  it "passes through a 304 Not Modified response" do
    @status, @headers, @data = 304, {}, nil
    call_response_validator
  end

  private

  def call_response_validator(strict = false)
    @operation_object = open_api_3_schema.operation_object(@path, @method)
    Committee::SchemaValidator::OpenAPI3::ResponseValidator.
        new(@operation_object, @validator_option).
        call(@status, @headers, @data, strict)
  end
end
