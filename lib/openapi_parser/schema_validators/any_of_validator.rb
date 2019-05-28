class OpenAPIParser::SchemaValidator
  class AnyOfValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      if schema.discriminator
        return validate_discriminator_schema(schema.discriminator, value)
      end

      # in all schema return error (=true) not any of data
      schema.any_of.each do |s|
        coerced, err = validatable.validate_schema(value, s)
        return [coerced, nil] if err.nil?
      end
      [nil, OpenAPIParser::NotAnyOf.new(value, schema.object_reference)]
    end
  end
end
