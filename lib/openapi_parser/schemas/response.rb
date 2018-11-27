# TODO: headers
# TODO: links

module OpenAPIParser::Schemas
  class Response < Base
    openapi_attr_values :description

    # @!attribute [r] content
    #   @return [Hash{String => MediaType}, nil]
    openapi_attr_hash_object :content, MediaType, reference: false
  end
end
