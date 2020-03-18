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

    SCHEMA_PROPERTIES_PAIR = [
        ['string', 'str'],
        ['integer', 1],
        ['boolean', true],
        ['boolean', false],
        ['number', 0.1],
    ]

    it 'correct data' do
      operation_object.validate_request_params({ "body" => SCHEMA_PROPERTIES_PAIR.to_h }, HEADER, @validator_option)
      assert true
    end

    it 'correct object data' do
      operation_object.validate_request_params({ "body" => {
                                     "object_1" =>
                                         {
                                             "string_1" => nil,
                                             "integer_1" => nil,
                                             "boolean_1" => nil,
                                             "number_1" => nil
                                         }
                                 }},
                                               HEADER,
                                               @validator_option)

      assert true
    end

    it 'invalid params' do
      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({ "body" => {"string" => 1}}, HEADER, @validator_option)
      }

      # FIXME: when ruby 2.3 dropped, fix because ruby 2.3 return Fixnum, ruby 2.4 or later return Integer
      assert_match(/expected string, but received #{1.class}: 1/i, e.message)
    end

    it 'support put method' do
      @method = "put"
      operation_object.validate_request_params({ "body" => {"string" => "str"}}, HEADER, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({ "body" => {"string" => 1}}, HEADER, @validator_option)
      }

      # FIXME: when ruby 2.3 dropped, fix because ruby 2.3 return Fixnum, ruby 2.4 or later return Integer
      assert_match(/expected string, but received #{1.class}: 1/i, e.message)
    end

    it 'support patch method' do
      @method = "patch"
      operation_object.validate_request_params({ "body" => {"integer" => 1}}, HEADER, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({ "body" => {"integer" => "str"}}, HEADER, @validator_option)
      }

      assert_match(/expected integer, but received String: str/i, e.message)
    end

    it 'unknown param' do
      operation_object.validate_request_params({ "body" => {"unknown" => 1}}, HEADER, @validator_option)
    end

    describe 'support get method' do
      before do
        @method = "get"
      end

      it 'correct' do
        operation_object.validate_request_params(
            { "query" => {"query_string" => "query", "query_integer_list" => [1, 2]}},
            HEADER,
            @validator_option
        )

        operation_object.validate_request_params(
            { "query" => {"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => 1}},
            HEADER,
            @validator_option
        )

        assert true
      end

      it 'not exist required' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({ "query" => {"query_integer_list" => [1, 2]}}, HEADER, @validator_option)
        }

        assert_match(/missing required parameters: query_string/i, e.message)
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params(
              { "query" => {"query_string" => 1, "query_integer_list" => [1, 2], "optional_integer" => 1}},
              HEADER,
              @validator_option
          )
        }

        # FIXME: when ruby 2.3 dropped, fix because ruby 2.3 return Fixnum, ruby 2.4 or later return Integer
        assert_match(/expected string, but received #{1.class}: 1/i, e.message)
      end
    end

    describe 'support delete method' do
      before do
        @path = '/characters'
        @method = "delete"
      end

      it 'correct' do
        operation_object.validate_request_params({ "form_data" => {"limit" => "1"}}, HEADER, @validator_option)

        assert true
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({ "form_data" => {"limit" => "a"}}, HEADER, @validator_option)
        }

        assert_match(/expected integer, but received String: a/i, e.message)
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
  end
end
