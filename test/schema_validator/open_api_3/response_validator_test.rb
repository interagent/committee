# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::OpenAPI3::ResponseValidator do
  before do
    @status = 200
    @headers = { "Content-Type" => "application/json" }
    @data = { "string" => "Honoka.Kousaka" }

    @path = '/validate'
    @method = 'post'

    @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
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

  describe 'allow_empty_date_and_datetime' do
    it "errors given an empty date string with allow_empty_date_and_datetime disabled" do
      @path = '/date_time'
      @method = 'get'
      @data = { 'date' => '' }

      e = assert_raises(Committee::InvalidResponse) {
        call_response_validator
      }
      assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
      assert_match(/\"\" is not conformant with date format/i, e.message)
    end

    it "errors given an empty date-time string with allow_empty_date_and_datetime disabled" do
      @path = '/date_time'
      @method = 'get'
      @data = { 'date-time' => '' }

      e = assert_raises(Committee::InvalidResponse) {
        call_response_validator
      }
      assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
      assert_match(/\"\" is not conformant with date-time format/i, e.message)
    end

    it "passes given an empty date string with allow_empty_date_and_datetime enabled" do
      @validator_option = Committee::SchemaValidator::Option.new(
        { allow_empty_date_and_datetime: true },
        open_api_3_schema,
        :open_api_3)

      @path = '/date_time'
      @method = 'get'
      @data = { 'date' => '' }

      if OpenAPIParser::VERSION >= "2.2.6"
        response = call_response_validator
        assert_equal({ 'date' => '' }, response)
      else
        e = assert_raises(Committee::InvalidResponse) {
          call_response_validator
        }
        assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
        assert_match(/\"\" is not conformant with date format/i, e.message)
      end
    end

    it "passes given an empty date-time string with allow_empty_date_and_datetime enabled" do
      @validator_option = Committee::SchemaValidator::Option.new(
        { allow_empty_date_and_datetime: true },
        open_api_3_schema,
        :open_api_3)

      @path = '/date_time'
      @method = 'get'
      @data = { 'date-time' => '' }

      if OpenAPIParser::VERSION >= "2.2.6"
        response = call_response_validator
        assert_equal({ 'date-time' => '' }, response)
      else
        e = assert_raises(Committee::InvalidResponse) {
          call_response_validator
        }
        assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
        assert_match(/\"\" is not conformant with date-time format/i, e.message)
      end
    end
  end

  private

  def call_response_validator(strict = false)
    @operation_object = open_api_3_schema.operation_object(@path, @method)
    Committee::SchemaValidator::OpenAPI3::ResponseValidator.
        new(@operation_object, @validator_option).
        call(@status, @headers, @data, strict)
  end
end
