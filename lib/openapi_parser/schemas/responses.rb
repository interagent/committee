# TODO: support extended property

module OpenAPIParser::Schemas
  class Responses < Base
    # @!attribute [r] default
    #   @return [Response, Reference, nil]
    openapi_attr_object :default, Response, reference: true

    # @!attribute [r] response
    #   @return [Hash{String => Response, Reference}, nil]
    openapi_attr_hash_body_objects 'response', Response, reject_keys: [:default], allow_reference: true, allow_data_type: false

    def validate_response_body(status_code, content_type, params)
      # TODO: support wildcard status code like 2XX
      return nil unless response

      res = response[status_code.to_s]
      return res.validate_parameter(content_type, params) if res

      default&.validate_parameter(content_type, params)
    end
  end
end
