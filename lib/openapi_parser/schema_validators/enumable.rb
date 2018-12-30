class OpenAPIParser::SchemaValidator
  module Enumable
    # check enum value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def check_enum_include(value, schema)
      return [value, nil] unless schema.enum
      return [value, nil] if schema.enum.include?(value)

      [nil, OpenAPIParser::NotEnumInclude.new(value, schema.object_reference)]
    end
  end
end
