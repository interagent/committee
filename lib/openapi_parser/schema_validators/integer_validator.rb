class OpenAPIParser::SchemaValidator
  class IntegerValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable
    include ::OpenAPIParser::SchemaValidator::MinimumMaximum

    # validate integer value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      value = coerce(value) if @coerce_value

      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Integer)

      check_enum_include(value, schema)
      check_minimum_maximum(value, schema)
    end

    private

      def coerce(value)
        return value if value.kind_of?(Integer)

        begin
          return Integer(value)
        rescue ArgumentError => e
          raise e unless e.message =~ /invalid value for Integer/
        end

        value
      end
  end
end
