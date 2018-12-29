class OpenAPIParser::SchemaValidator
  class ArrayValidator < Base
    # @param [Array] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Array)

      # array type have an schema in items property
      items_schema = schema.items

      coerced_values = value.map do |v|
        coerced, err = validatable.validate_schema(v, items_schema)
        return [nil, err] if err

        coerced
      end

      value.each_index { |idx| value[idx] = coerced_values[idx] } if @coerce_value

      [value, nil]
    end
  end
end
