# TODO: example
# TODO: examples
# TODO: encoding

module OpenAPIParser::Schemas
  class MediaType < Base
    # @!attribute [r] schema
    #   @return [Schema, nil]
    openapi_attr_object :schema, Schema, reference: true

    # @param [Hash] params
    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_parameter(params, options)
      OpenAPIParser::SchemaValidator.validate(params, schema, options)
    end
  end
end
