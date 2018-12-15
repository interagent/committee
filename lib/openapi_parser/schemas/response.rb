# TODO: headers
# TODO: links

module OpenAPIParser::Schemas
  class Response < Base
    openapi_attr_values :description

    # @!attribute [r] content
    #   @return [Hash{String => MediaType}, nil]
    openapi_attr_hash_object :content, MediaType, reference: false

    def validate_parameter(content_type, params)
      # TODO: support wildcard type like application/* (OpenAPI3 definition)

      media_type = content[content_type]
      return nil unless media_type

      media_type.validate_parameter(params)
    end
  end
end
