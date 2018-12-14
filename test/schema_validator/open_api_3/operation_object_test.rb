require_relative "../../test_helper"

require "stringio"

describe Committee::SchemaValidator::OpenAPI3::OperationObject do
  describe 'validate' do
    before do
      @path = '/validate'
      @method = 'post'
      @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
    end

    def operation_object
      open_api_3_schema.operation_object(@path, @method)
    end

    SCHEMA_PROPERTIES_PAIR = [
        ['string', 'str'],
        ['integer', 1],
        ['boolean', true],
        ['boolean', false],
        ['number', 0.1],
    ]

    it 'correct data' do
      operation_object.validate_request_params(SCHEMA_PROPERTIES_PAIR.to_h)
      assert true
    end

    it 'correct object data' do
      operation_object.validate_request_params({
                                     "object_1" =>
                                         {
                                             "string_1" => nil,
                                             "integer_1" => nil,
                                             "boolean_1" => nil,
                                             "number_1" => nil
                                         }
                                 })

      assert true
    end

    it 'invalid params' do
      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"string" => 1})
      }

      assert e.message.start_with?("1 class is Integer but it's not valid")
    end

    it 'support put method' do
      @method = "put"
      operation_object.validate_request_params({"string" => "str"})

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"string" => 1})
      }
      assert e.message.start_with?("1 class is Integer but it's not valid")
    end

    it 'support patch method' do
      @method = "patch"
      operation_object.validate_request_params({"integer" => 1})

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"integer" => "str"})
      }

      assert e.message.start_with?("str class is String but it's not valid")
    end

    it 'unknown param' do
      operation_object.validate_request_params({"unknown" => 1})
    end

    describe 'support get method' do
      before do
        @method = "get"
      end

      it 'correct' do
        operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2]})
        operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => 1})

        assert true
      end

      it 'not exist required' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_integer_list" => [1, 2]})
        }

        assert e.message.start_with?("required parameters query_string not exist")

        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_string" => "query"})
        }

        assert e.message.start_with?("required parameters query_integer_list not exist")
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_string" => 1, "query_integer_list" => [1, 2], "optional_integer" => 1})
        }

        assert e.message.start_with?("invalid parameter type query_string 1 Integer string")

        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => ['1', 2], "optional_integer" => 1})
        }

        assert e.message.start_with?("invalid parameter type query_integer_list 1 String integer")

        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => '1'})
        }

        assert e.message.start_with?("invalid parameter type optional_integer 1 String integer")
      end
    end
  end
end
