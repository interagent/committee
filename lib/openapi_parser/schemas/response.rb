# TODO: headers
# TODO: links

module OpenAPIParser::Schemas
  class Response < Base
    include OpenAPIParser::MediaTypeSelectable

    openapi_attr_values :description

    # @!attribute [r] content
    #   @return [Hash{String => MediaType}, nil] content_type to MediaType hash
    openapi_attr_hash_object :content, MediaType, reference: false

    # @param [String] content_type
    # @param [Hash] params
    # @param [OpenAPIParser::SchemaValidator::ResponseValidateOptions] response_validate_options
    def validate_parameter(content_type, params, response_validate_options)
      media_type = select_media_type(content_type)
      unless media_type
        raise ::OpenAPIParser::NotExistContentTypeDefinition, object_reference if response_validate_options.strict

        return nil
      end

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
