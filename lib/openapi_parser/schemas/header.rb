module OpenAPIParser::Schemas
  class Header < Base
    openapi_attr_values :description, :required, :deprecated, :style, :explode, :example

    openapi_attr_value :allow_empty_value, schema_key: :allowEmptyValue
    openapi_attr_value :allow_reserved, schema_key: :allowReserved

    # @!attribute [r] schema
    #   @return [Schema, Reference, nil]
    openapi_attr_object :schema, Schema, reference: true

    # validate by schema
    # @param [Object] value
    def validate(value)
      OpenAPIParser::SchemaValidator.validate(value, schema, OpenAPIParser::SchemaValidator::Options.new)
    end
  end
end
