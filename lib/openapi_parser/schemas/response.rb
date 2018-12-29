# TODO: headers
# TODO: links

module OpenAPIParser::Schemas
  class Response < Base
    include OpenAPIParser::MediaTypeSelectable

    openapi_attr_values :description

    # @!attribute [r] content
    #   @return [Hash{String => MediaType}, nil] content_type to MediaType hash
    openapi_attr_hash_object :content, MediaType, reference: false

    def validate_parameter(content_type, params)
      media_type = select_media_type(content_type, content)
      return nil unless media_type

      options = ::OpenAPIParser::SchemaValidator::Options.new # response validator not support any options
      media_type.validate_parameter(params, options)
    end
  end
end
