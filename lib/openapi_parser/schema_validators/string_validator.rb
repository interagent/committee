class OpenAPIParser::SchemaValidator
  class StringValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def initialize(validator, coerce_value, coerce_datetime)
      super(validator, coerce_value)
      @coerce_datetime = coerce_datetime
    end

    def coerce_and_validate(value, schema)
      value = coerce(value) if @coerce_value

      return validator.validate_error(value, schema) unless value.is_a?(String)

      check_enum_include(value, schema)
    end

    private

    def coerce(value)
      value
    end
  end
end
