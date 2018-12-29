# TODO: support extended property

module OpenAPIParser::Schemas
  class RequestBody < Base
    include OpenAPIParser::MediaTypeSelectable

    # @!attribute [r] description
    #   @return [String] description data
    # @!attribute [r] required
    #   @return [Boolean] required bool data
    openapi_attr_values :description, :required

    # @!attribute [r] content
    #   @return [Hash{String => MediaType}, nil] content type to MediaType object
    openapi_attr_hash_object :content, MediaType, reference: false

    # @param [String] content_type
    # @param [Hash] params
    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_request_body(content_type, params, options)
      media_type = select_media_type(content_type, content)
      return params unless media_type

      media_type.validate_parameter(params, options)
    end
  end
end
