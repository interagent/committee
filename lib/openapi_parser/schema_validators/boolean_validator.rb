class OpenAPIParser::SchemaValidator
  class BooleanValidator < Base
    TRUE_VALUES = ['true', '1'].freeze
    FALSE_VALUES = ['false', '0'].freeze

    def coerce_and_validate(value, schema)
      value = coerce(value) if @coerce_value

      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(TrueClass) || value.kind_of?(FalseClass)

      [value, nil]
    end

    private

      def coerce(value)
        return true if TRUE_VALUES.include?(value)

        return false if FALSE_VALUES.include?(value)

        value
      end
  end
end
