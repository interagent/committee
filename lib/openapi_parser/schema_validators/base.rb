class OpenAPIParser::SchemaValidator
  class Base
    # @param [OpenAPIParser::SchemaValidator::Validatable] validatable
    def initialize(validatable, coerce_value)
      @validatable = validatable
      @coerce_value = coerce_value
    end

    attr_reader :validatable

    # @!attribute [r] validatable
    #   @return [OpenAPIParser::SchemaValidator::Validatable]

    # need override
    # @param [Array] _value
    # @param [OpenAPIParser::Schemas::Schema] _schema
    def coerce_and_validate(_value, _schema)
      raise 'need implement'
    end
  end
end
