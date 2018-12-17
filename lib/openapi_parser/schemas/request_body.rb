# TODO: support extended property

module OpenAPIParser::Schemas
  class RequestBody < Base
    openapi_attr_values :description, :required

    # @!attribute [r] content
    #   @return [Hash{String => MediaType}, nil]
    openapi_attr_hash_object :content, MediaType, reference: false

    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_request_body(_content_type, params, options)
      # TODO: now support application/json only :(

      media_type = content['application/json']
      return params unless media_type

      media_type.validate_parameter(params, options)
    end
  end
end
