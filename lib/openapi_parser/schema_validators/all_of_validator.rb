# validate AllOf schema
class OpenAPIParser::SchemaValidator
  class AllOfValidator < Base
    # coerce and validate value
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema)
      # if any schema return error, it's not valida all of value
      remaining_keys               = value.keys
      nested_additional_properties = false
      schema.all_of.each do |s|
        # We need to store the reference to all of, so we can perform strict check on allowed properties
        _coerced, err = validatable.validate_schema(value, s, :parent_all_of => true)

        if s.properties
          remaining_keys               -= s.properties.keys
          nested_additional_properties = true if s.additional_properties
        end

        return [nil, err] if err
      end

      # If there are nested additionalProperites, we allow not defined extra properties and lean on the specific
      # additionalProperties validation
      if !nested_additional_properties && !remaining_keys.empty?
        return [nil, OpenAPIParser::NotExistPropertyDefinition.new(remaining_keys, schema.object_reference)]
      end

      [value, nil]
    end
  end
end
