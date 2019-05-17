class OpenAPIParser::SchemaValidator
  class ObjectValidator < Base
    # @param [Hash] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Hash)

      return [value, nil] unless schema.properties

      required_set = schema.required ? schema.required.to_set : Set.new

      coerced_values = value.map do |name, v|
        s = schema.properties[name]
        coerced, err = if s
                         validatable.validate_schema(v, s)
                       else
                         # Property is not defined, try validate using additionalProperties
                         validate_using_additional_properties(schema, name, v)
                       end

        return [nil, err] if err

        required_set.delete(name)
        [name, coerced]
      end

      return [nil, OpenAPIParser::NotExistRequiredKey.new(required_set.to_a, schema.object_reference)] unless required_set.empty?

      value.merge!(coerced_values.to_h) if @coerce_value

      [value, nil]
    end

    def validate_using_additional_properties(schema, name, v)
      unless schema.additional_properties
        if schema.parent_all_of
          return [v, nil] if property_defined_in_all_of?(schema, name)
        end

        # Property name is not defined in this schema, nor in any schema in the allOf definition, raise a failure.
        return [nil, OpenAPIParser::NotExistPropertyDefinition.new(name, schema.object_reference)]
      end

      # TODO: we need to perform a validation based on additionalProperties here
      return [v, nil]
    end

    def property_defined_in_all_of?(schema, name)
      schema.parent_all_of.each do |s|
        # Skip the current schema
        next if schema == s

        # If one of the composable schemas defined in allOf has the property name defined, we can skip it here, it will
        # be validated in that particular schema.
        return true if s.properties && s.properties.key?(name)

        # If one of the composable schemas defined in allOf has additional_properties, we can skip the validation here,
        # it will be validated in that particular schema.
        return true if s.additional_properties
      end

      false
    end
  end
end
