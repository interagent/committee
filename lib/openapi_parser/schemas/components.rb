# TODO: examples
# TODO: securitySchemes
# TODO: links
# TODO: callbacks

module OpenAPIParser::Schemas
  class Components < Base
    # @!attribute [r] parameters
    #   @return [Hash{String => Parameter}, nil]
    openapi_attr_hash_object :parameters, Parameter, reference: true

    # @!attribute [r] parameters
    #   @return [Hash{String => Parameter}, nil]
    openapi_attr_hash_object :schemas, Schema, reference: true

    # @!attribute [r] responses
    #   @return [Hash{String => Response}, nil]
    openapi_attr_hash_object :responses, Response, reference: true

    # @!attribute [r] request_bodies
    #   @return [Hash{String => RequestBody}, nil]
    openapi_attr_hash_object :request_bodies, RequestBody, reference: true, schema_key: :requestBodies

    # @!attribute [r] headers
    #   @return [Hash{String => Header}, nil] header objects
    openapi_attr_hash_object :headers, Header, reference: true
  end
end
