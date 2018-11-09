require_relative "../../test_helper"

require "stringio"

describe Committee::SchemaValidator::OpenAPI3::OperationObject do
  describe 'validate' do
    before do
      path = '/validate'
      method = 'post'
      @operation_object = open_api_3_schema.operation_object(path, method)
      @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
    end

    SCHEMA_PROPERTIES_PAIR = [
        ['string_1', 'str'],
        ['integer_1', 1],
        ['boolean_1', true],
        ['boolean_1', false],
        ['number_1', 0.1],
    ]

    it 'correct data' do
      @operation_object.validate(SCHEMA_PROPERTIES_PAIR.to_h)
      assert true
    end

    it 'correct object data' do
      @operation_object.validate({
                                     "object_1" =>
                                         {
                                             "string_2" => nil,
                                             "integer_2" => nil,
                                             "boolean_2" => nil,
                                             "number_2" => nil
                                         }
                                 })

      assert true
    end

    it 'invalid params' do
      invalids = [
          ['string_1', 1],
          ['string_1', true],
          ['string_1', false],
          ['string_1', nil],
          ['integer_1', '1'],
          ['integer_1', 0.1],
          ['integer_1', true],
          ['integer_1', false],
          ['boolean_1', 1],
          ['boolean_1', 'true'],
          ['boolean_1', 'false'],
          ['boolean_1', '0.1'],
          ['number_1', '0.1'],
          ['number_1', true],
          ['number_1', false],
      ]

      invalids.each do |key, value|
        e = assert_raises(Committee::InvalidRequest) {
          @operation_object.validate({"#{key}" => value})
        }

        assert e.message.start_with?("invalid parameter type #{key}")
      end
    end

    it 'unknown param' do
      @operation_object.validate({"unknown" => 1})
    end
  end
end
