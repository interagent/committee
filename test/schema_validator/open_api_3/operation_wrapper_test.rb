# frozen_string_literal: true

require "test_helper"

require "stringio"

describe Committee::SchemaValidator::OpenAPI3::OperationWrapper do
  describe 'validate' do
    before do
      @path = '/validate'
      @method = 'post'
      @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
    end

    def operation_object
      open_api_3_schema.operation_object(@path, @method)
    end

    HEADER = { 'Content-Type' => 'application/json' }

    SCHEMA_PROPERTIES_PAIR = [['string', 'str'], ['integer', 1], ['boolean', true], ['boolean', false], ['number', 0.1],]

    it 'correct data' do
      operation_object.validate_request_params({}, {}, SCHEMA_PROPERTIES_PAIR.to_h, HEADER, @validator_option)
      assert true
    end

    it 'correct object data' do
      operation_object.validate_request_params({}, {}, { "object_1" => { "string_1" => nil, "integer_1" => nil, "boolean_1" => nil, "number_1" => nil } }, HEADER, @validator_option)

      assert true
    end

    it 'invalid params' do
      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({}, {}, { "string" => 1 }, HEADER, @validator_option)
      }

      assert_match(/expected string, but received Integer: 1/i, e.message)
      assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
    end

    it 'support put method' do
      @method = "put"
      operation_object.validate_request_params({}, {}, { "string" => "str" }, HEADER, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({}, {}, { "string" => 1 }, HEADER, @validator_option)
      }

      assert_match(/expected string, but received Integer: 1/i, e.message)
      assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
    end

    it 'support patch method' do
      @method = "patch"
      operation_object.validate_request_params({}, {}, { "integer" => 1 }, HEADER, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({}, {}, { "integer" => "str" }, HEADER, @validator_option)
      }

      assert_match(/expected integer, but received String: "str"/i, e.message)
      assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
    end

    it 'unknown param' do
      operation_object.validate_request_params({}, {}, { "unknown" => 1 }, HEADER, @validator_option)
    end

    describe 'support get method' do
      before do
        @method = "get"
      end

      it 'correct' do
        operation_object.validate_request_params({}, { "query_string" => "query", "query_integer_list" => [1, 2] }, {}, HEADER, @validator_option)

        operation_object.validate_request_params({}, { "query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => 1 }, {}, HEADER, @validator_option)

        assert true
      end

      it 'not exist required' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({}, { "query_integer_list" => [1, 2] }, {}, HEADER, @validator_option)
        }

        assert_match(/missing required parameters: query_string/i, e.message)
        assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({}, { "query_string" => 1, "query_integer_list" => [1, 2], "optional_integer" => 1 }, {}, HEADER, @validator_option)
        }

        assert_match(/expected string, but received Integer: 1/i, e.message)
        assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
      end
    end

    describe 'support delete method' do
      before do
        @path = '/characters'
        @method = "delete"
      end

      it 'correct' do
        operation_object.validate_request_params({}, { "limit" => "1" }, {}, HEADER, @validator_option)

        assert true
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({}, { "limit" => "a" }, {}, HEADER, @validator_option)
        }

        assert_match(/expected integer, but received String: "a"/i, e.message)
        assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
      end
    end

    describe 'support head method' do
      before do
        @path = '/characters'
        @method = 'head'
      end

      it 'correct' do
        operation_object.validate_request_params({}, { "limit" => "1" }, {}, HEADER, @validator_option)

        assert true
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({}, { "limit" => "a" }, {}, HEADER, @validator_option)
        }

        assert_match(/expected integer, but received String: "a"/i, e.message)
        assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
      end
    end

    it 'support options method' do
      @method = "options"
      operation_object.validate_request_params({}, {}, { "integer" => 1 }, HEADER, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({}, {}, { "integer" => "str" }, HEADER, @validator_option)
      }

      assert_match(/expected integer, but received String: "str"/i, e.message)
      assert_kind_of(OpenAPIParser::OpenAPIError, e.original_error)
    end

    describe '#content_types' do
      it 'returns supported content types' do
        @path = '/validate_content_types'
        @method = 'post'

        assert_equal ["application/json", "application/binary"], operation_object.request_content_types
      end

      it 'returns an empty array when the content of requestBody does not exist' do
        @path = '/characters'
        @method = 'get'

        assert_equal [], operation_object.request_content_types
      end
    end

    describe 'coercion option wiring' do
      before do
        @path = '/coerce_path_params/1'
        @method = 'get'
      end

      it 'uses coerce_path_params for explicit path coercion' do
        disabled = Committee::SchemaValidator::Option.new({ coerce_path_params: false, coerce_query_params: true }, open_api_3_schema, :open_api_3)
        enabled = Committee::SchemaValidator::Option.new({ coerce_path_params: true, coerce_query_params: false }, open_api_3_schema, :open_api_3)

        error = assert_raises(Committee::InvalidRequest) do
          operation_object.coerce_path_parameter(disabled)
        end
        assert_match(/expected integer, but received String: "1"/i, error.message)

        coerced = operation_object.coerce_path_parameter(enabled)
        assert_kind_of(Integer, coerced['integer'])
      end

      it 'uses coerce_query_params for request parameter validation' do
        query_coercion_disabled = Committee::SchemaValidator::Option.new({ coerce_query_params: false }, open_api_3_schema, :open_api_3)
        query_coercion_enabled = Committee::SchemaValidator::Option.new({ coerce_query_params: true }, open_api_3_schema, :open_api_3)

        error = assert_raises(Committee::InvalidRequest) do
          @path = '/characters'
          operation_object.validate_request_params({}, { "limit" => "1" }, {}, HEADER, query_coercion_disabled)
        end
        assert_match(/expected integer, but received String: "1"/i, error.message)

        @path = '/characters'
        operation_object.validate_request_params({}, { "limit" => "1" }, {}, HEADER, query_coercion_enabled)
      end
    end
  end
end
