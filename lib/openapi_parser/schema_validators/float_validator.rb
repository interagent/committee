class OpenAPIParser::SchemaValidator
  class FloatValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def coerce_and_validate(value, schema)
      value = coerce(value) if @coerce_value

      return validator.validate_integer(value, schema) if value.is_a?(Integer)
      coercer_and_validate_numeric(value, schema)
    end

    private

    def coercer_and_validate_numeric(value, schema)
      return validator.validate_error(value, schema) unless value.is_a?(Numeric)
      check_enum_include(value, schema)
    end

    private

    def coerce(value)
      begin
        return Float(value)
      rescue ArgumentError => e
        raise e unless e.message =~ /invalid value for Float/
      end
    end
  end
end
