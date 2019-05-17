# validate AllOf schema
class OpenAPIParser::SchemaValidator
  class AllOfValidator < Base
    # coerce and validate value
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema)
      # if any schema return error, it's not valida all of value
      schema.all_of.each do |s|
        # We need to store the reference to all of, so we can perform strict check on allowed properties
        s.parent_all_of = schema.all_of

        _coerced, err = validatable.validate_schema(value, s)
        return [nil, err] if err
      end
      [value, nil]
    end
  end
end
