class OpenAPIParser::SchemaValidator
  class StringValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def initialize(validator, coerce_value, datetime_coerce_class)
      super(validator, coerce_value)
      @datetime_coerce_class = datetime_coerce_class
    end

    def coerce_and_validate(value, schema)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(String)

      value, err = check_enum_include(value, schema)
      return [nil, err] if err

      value = coerce_date_time(value, schema) unless @datetime_coerce_class.nil?

      [value, nil]
    end

    private

      # @param [OpenAPIParser::Schemas::Schema] schema
      def coerce_date_time(value, schema)
        (schema.format == 'date-time') ? parse_date_time(value) : value
      end

      def parse_date_time(value)
        begin
          return @datetime_coerce_class.parse(value)
        rescue ArgumentError => e
          raise e unless e.message =~ /invalid date/
        end

        value
      end
  end
end
