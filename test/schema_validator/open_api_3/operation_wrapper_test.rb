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

    describe 'same-named path and query parameters' do
      %w[get post].each do |method|
        describe method do
          before do
            @path = '/overwrite_same_parameter/123'
            @method = method
            data = open_api_3_data
            path_item = data['paths']['/overwrite_same_parameter/{integer}']
            path_item[method] = path_item['post']
            @open_api_3_schema = Committee::Drivers.load_from_data(data, open_api_3_schema_path, parser_options: { strict_reference_validation: true })
          end

          it 'rejects an invalid query value without overwriting it with the path value' do
            path_params = { 'integer' => 123 }
            query_params = { 'integer' => 'not-an-integer' }

            error = assert_raises(Committee::InvalidRequest) do
              operation_object.validate_request_params(path_params, query_params, {}, HEADER, @validator_option)
            end

            assert_match(/expected integer, but received String: "not-an-integer"/i, error.message)
            assert_kind_of(OpenAPIParser::OpenAPIError, error.original_error)
            assert_equal({ 'integer' => 'not-an-integer' }, query_params)
            assert_equal({ 'integer' => 123 }, path_params)
          end

          it 'rejects a missing required query parameter even when the path parameter is present' do
            error = assert_raises(Committee::InvalidRequest) do
              operation_object.validate_request_params({ 'integer' => 123 }, {}, {}, HEADER, @validator_option)
            end

            assert_match(/missing required parameters: integer/i, error.message)
          end

          it 'coerces the query value independently of the path value' do
            path_params = { 'integer' => 123 }
            query_params = { 'integer' => '456' }

            operation_object.validate_request_params(path_params, query_params, {}, HEADER, @validator_option)

            assert_equal({ 'integer' => 123 }, path_params)
            assert_equal({ 'integer' => 456 }, query_params)
          end

          it 'honors disabled query coercion even when the path value is already an integer' do
            options = Committee::SchemaValidator::Option.new({ coerce_query_params: false }, open_api_3_schema, :open_api_3)

            error = assert_raises(Committee::InvalidRequest) do
              operation_object.validate_request_params({ 'integer' => 123 }, { 'integer' => '456' }, {}, HEADER, options)
            end

            assert_match(/expected integer, but received String: "456"/i, error.message)
          end
        end
      end
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

      it 'uses coerce_form_params for JSON request bodies too' do
        @path = '/validate'
        @method = 'post'

        body_coercion_disabled = Committee::SchemaValidator::Option.new({ coerce_form_params: false }, open_api_3_schema, :open_api_3)
        body_coercion_enabled = Committee::SchemaValidator::Option.new({ coerce_form_params: true }, open_api_3_schema, :open_api_3)

        error = assert_raises(Committee::InvalidRequest) do
          operation_object.validate_request_params({}, {}, { "integer" => "1" }, HEADER, body_coercion_disabled)
        end
        assert_match(/expected integer, but received String: "1"/i, error.message)

        body_params = { "integer" => "1" }
        operation_object.validate_request_params({}, {}, body_params, HEADER, body_coercion_enabled)

        assert_kind_of(Integer, body_params["integer"])
      end
    end

    describe '#find_response_object_for_status' do
      def responses_for(path, method = 'get')
        open_api_3_schema.operation_object(path, method).request_operation.operation_object.responses
      end

      def find(path, status, method = 'get')
        wrapper = open_api_3_schema.operation_object(path, method)
        wrapper.send(:find_response_object_for_status, responses_for(path, method), status)
      end

      it 'returns nil when responses is nil' do
        wrapper = open_api_3_schema.operation_object('/characters', 'get')
        assert_nil wrapper.send(:find_response_object_for_status, nil, 200)
      end

      it 'returns exact status code match' do
        result = find('/characters', 200)
        assert_kind_of OpenAPIParser::Schemas::Response, result
        assert result.content.key?('application/json')
      end

      it 'returns wildcard match when exact status not defined' do
        result = find('/wildcard_response', 400)
        assert_kind_of OpenAPIParser::Schemas::Response, result
        assert result.content.key?('application/json')
      end

      it 'returns default when no exact or wildcard match' do
        result = find('/default_response', 500)
        assert_kind_of OpenAPIParser::Schemas::Response, result
        assert result.content.key?('application/json')
      end

      it 'returns nil when no exact, wildcard, or default match' do
        assert_nil find('/characters', 999)
      end
    end
  end
end
