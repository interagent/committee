class OpenAPIParser::SchemaValidator
  class IntegerValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def coerce_and_validate(value, schema)
      value = coerce(value) if @coerce_value

      return validator.validate_error(value, schema) unless value.is_a?(Integer)
      check_enum_include(value, schema)
    end

    private

    def coerce(value)
      begin
        return Integer(value)
      rescue ArgumentError => e
        raise e unless e.message =~ /invalid value for Integer/
      end
    end
  end
end
