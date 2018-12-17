class OpenAPIParser::SchemaValidator
  class ObjectValidator < Base

    # @param [Hash] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema)
      validator.validate_error(value, schema) unless value.is_a?(Hash)

      return [value, nil] unless schema.properties
      required_set = schema.required ? schema.required.to_set : Set.new

      value.each do |name, v|
        s = schema.properties[name]
        _coerced, err = validator.validate_schema(v, s)
        return [nil, err] if err

        required_set.delete(name)
      end

      return [nil, OpenAPIParser::NotExistRequiredKey.new(required_set.to_a, schema.object_reference)] unless required_set.empty?
      [value, nil]
    end
  end
end
