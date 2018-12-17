class OpenAPIParser::SchemaValidator
  class BooleanValidator < Base
    def coerce_and_validate(value, schema)
      value = coerce(value) if @coerce_value

      return validator.validate_error(value, schema) unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
      [value, nil]
    end

    private

    def coerce(value)
      if value == "true" || value == "1"
        return true
      end
      if value == "false" || value == "0"
        return false
      end
      value
    end
  end
end
