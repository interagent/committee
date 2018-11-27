# TODO: support extended property

module OpenAPIParser::Schemas
  class Responses < Base
    # @!attribute [r] default
    #   @return [Response, Reference, nil]
    openapi_attr_object :default, Response, reference: true

    # @!attribute [r] response
    #   @return [Hash{String => Response, Reference}, nil]
    openapi_attr_hash_body_objects 'response', Response, reject_keys: [:default], allow_reference: true, allow_data_type: false
  end
end
