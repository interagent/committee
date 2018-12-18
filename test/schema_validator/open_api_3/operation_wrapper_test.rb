require_relative "../../test_helper"

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

    SCHEMA_PROPERTIES_PAIR = [
        ['string', 'str'],
        ['integer', 1],
        ['boolean', true],
        ['boolean', false],
        ['number', 0.1],
    ]

    it 'correct data' do
      operation_object.validate_request_params(SCHEMA_PROPERTIES_PAIR.to_h, @validator_option)
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
                                 },
                                               @validator_option)

      assert true
    end

    it 'invalid params' do
      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"string" => 1}, @validator_option)
      }

      assert e.message.start_with?("1 class is Integer but it's not valid")
    end

    it 'support put method' do
      @method = "put"
      operation_object.validate_request_params({"string" => "str"}, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"string" => 1}, @validator_option)
      }
      assert e.message.start_with?("1 class is Integer but it's not valid")
    end

    it 'support patch method' do
      @method = "patch"
      operation_object.validate_request_params({"integer" => 1}, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"integer" => "str"}, @validator_option)
      }

      assert e.message.start_with?("str class is String but it's not valid")
    end

    it 'unknown param' do
      operation_object.validate_request_params({"unknown" => 1}, @validator_option)
    end

    describe 'support get method' do
      before do
        @method = "get"
      end

      it 'correct' do
        operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2]}, @validator_option)
        operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => 1}, @validator_option)

        assert true
      end

      it 'not exist required' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_integer_list" => [1, 2]}, @validator_option)
        }

        assert e.message.start_with?("required parameters query_string not exist in")
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_string" => 1, "query_integer_list" => [1, 2], "optional_integer" => 1}, @validator_option)
        }
        assert e.message.start_with?("1 class is Integer but")
      end
    end
  end
end
