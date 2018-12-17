class OpenAPIParser::SchemaValidator
  class Base
    def initialize(validator, coerce_value)
      @validator = validator
      @coerce_value = coerce_value
    end

    attr_reader :validator

    # @!attribute [r] validator
    #   @return [OpenAPIParser::SchemaValidator]

    # return  [coerced_value, error]
    def coerce_and_validate(_value, _schema)
      raise 'need implement'
    end
  end
end
