module OpenAPIParser::Schemas
  class Paths < Base
    # @!attribute [r] path
    #   @return [Hash{String => PathItem, Reference}, nil]
    openapi_attr_hash_body_objects 'path', PathItem, allow_reference: false, allow_data_type: false
  end
end
