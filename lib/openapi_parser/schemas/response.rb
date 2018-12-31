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
      media_type = select_media_type(content_type)
      return nil unless media_type

      options = ::OpenAPIParser::SchemaValidator::Options.new # response validator not support any options
      media_type.validate_parameter(params, options)
    end

    # select media type by content_type (consider wild card definition)
    # @param [String] content_type
    # @return [OpenAPIParser::Schemas::MediaType, nil]
    def select_media_type(content_type)
      select_media_type_from_content(content_type, content)
    end
  end
end
