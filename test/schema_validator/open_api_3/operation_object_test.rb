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
        ['string', 'str'],
        ['integer', 1],
        ['boolean', true],
        ['boolean', false],
        ['number', 0.1],
    ]

    it 'correct data' do
      @operation_object.validate(SCHEMA_PROPERTIES_PAIR.to_h)
      assert true
    end

    it 'correct object data' do
      @operation_object.validate({
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
      invalids = [
          ['string', 1],
          ['string', true],
          ['string', false],
          ['string', nil],
          ['integer', '1'],
          ['integer', 0.1],
          ['integer', true],
          ['integer', false],
          ['boolean', 1],
          ['boolean', 'true'],
          ['boolean', 'false'],
          ['boolean', '0.1'],
          ['number', '0.1'],
          ['number', true],
          ['number', false],
      ]

      invalids.each do |key, value|
        e = assert_raises(Committee::InvalidRequest) {
          @operation_object.validate({"#{key}" => value})
        }

        assert e.message.start_with?("invalid parameter type #{key}")
      end
    end

    it 'required params' do
      object_2 = {
          "string_2" => "str",
          "integer_2" => 1,
          "boolean_2" => true,
          "number_2" => 0.1
      }

      object_2.keys.each do |key|
        deleted_object = object_2.reject{|k, _v| k == key}
        e = assert_raises(Committee::InvalidRequest) {
          @operation_object.validate({"object_2" => deleted_object})
        }

        assert e.message.start_with?("required parameters #{key} not exist")
      end

      e = assert_raises(Committee::InvalidRequest) {
        @operation_object.validate({"object_2" => {}})
      }

      assert e.message.start_with?("required parameters #{object_2.keys.join(",")} not exist")
    end

    it 'unknown param' do
      @operation_object.validate({"unknown" => 1})
    end
  end
end
