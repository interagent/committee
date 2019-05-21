class OpenAPIParser::SchemaValidator
  class ObjectValidator < Base
    # @param [Hash] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    # @param [Boolean] parent_all_of true if component is nested under allOf
    def coerce_and_validate(value, schema, parent_all_of: false)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Hash)

      return [value, nil] unless schema.properties

      required_set = schema.required ? schema.required.to_set : Set.new
      remaining_keys = value.keys

      coerced_values = value.map do |name, v|
        s = schema.properties[name]
        coerced, err = if s
                         remaining_keys.delete(name)
                         validatable.validate_schema(v, s)
                       else
                         # If object is nested in all of, the validation is already done in allOf validator. Or if
                         # additionalProperites are defined, we will validate using that
                         remaining_keys.clear if parent_all_of || schema.additional_properties
                         # Property is not defined, try validate using additionalProperties
                         validate_using_additional_properties(schema, name, v) if schema.additional_properties
                       end

        return [nil, err] if err

        required_set.delete(name)
        [name, coerced]
      end

      return [nil, OpenAPIParser::NotExistPropertyDefinition.new(remaining_keys, schema.object_reference)] unless remaining_keys.empty?
      return [nil, OpenAPIParser::NotExistRequiredKey.new(required_set.to_a, schema.object_reference)] unless required_set.empty?

      value.merge!(coerced_values.to_h) if @coerce_value

      [value, nil]
    end

    def validate_using_additional_properties(schema, name, v)
      # TODO: we need to perform a validation based on additionalProperties here

      return [v, nil]
    end
  end
end
