# TODO: example
# TODO: examples
# TODO: encoding

module OpenAPIParser::Schemas
  class MediaType < Base
    # @!attribute [r] schema
    #   @return [Schema, nil]
    openapi_attr_object :schema, Schema, reference: true

    # @param [Hash] params
    def validate_parameter(params, coerce)
      OpenAPIParser::SchemaValidator.validate(params, schema, coerce)
    end
  end
end
