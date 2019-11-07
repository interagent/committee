class OpenAPIParser::SchemaValidator
  class ArrayValidator < Base
    # @param [Array] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Array)

      value, err = validate_max_min_items(value, schema)
      return [nil, err] if err

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

    def validate_max_min_items(value, schema)
      return [nil, OpenAPIParser::MoreThanMaxItems.new(value, schema.object_reference)] if schema.maxItems && value.length > schema.maxItems
      return [nil, OpenAPIParser::LessThanMinItems.new(value, schema.object_reference)] if schema.minItems && value.length < schema.minItems

      [value, nil]
    end
  end
end
