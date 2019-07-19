class OpenAPIParser::SchemaValidator
  class FloatValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable
    include ::OpenAPIParser::SchemaValidator::MinimumMaximum

    # validate float value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      value = coerce(value) if @coerce_value

      return validatable.validate_integer(value, schema) if value.kind_of?(Integer)

      coercer_and_validate_numeric(value, schema)
    end

    private

      def coercer_and_validate_numeric(value, schema)
        return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Numeric)

        check_enum_include(value, schema)
        check_minimum_maximum(value, schema)
      end

      def coerce(value)
        Float(value)
      rescue ArgumentError => e
        raise e unless e.message =~ /invalid value for Float/
      end
  end
end
