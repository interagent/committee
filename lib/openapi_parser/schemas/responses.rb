# TODO: support extended property

module OpenAPIParser::Schemas
  class Responses < Base
    # @!attribute [r] default
    #   @return [Response, Reference, nil] default response object
    openapi_attr_object :default, Response, reference: true

    # @!attribute [r] response
    #   @return [Hash{String => Response, Reference}, nil] response object indexed by status code. see: https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#patterned-fields-1
    openapi_attr_hash_body_objects 'response', Response, reject_keys: [:default], reference: true, allow_data_type: false

    # validate params data by definition
    # find response object by status_code and content_type
    # https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#patterned-fields-1
    # @param [OpenAPIParser::RequestOperation::ValidatableResponseBody] response_body
    # @param [OpenAPIParser::SchemaValidator::ResponseValidateOptions] response_validate_options
    def validate(response_body, response_validate_options)
      return nil unless response

      if (res = find_response_object(response_body.status_code))

        return res.validate(response_body, response_validate_options)
      end

      raise ::OpenAPIParser::NotExistStatusCodeDefinition, object_reference if response_validate_options.strict

      nil
    end

    private

      # @param [Integer] status_code
      # @return [Response]
      def find_response_object(status_code)
        if (res = response[status_code.to_s])
          return res
        end

        wild_card = status_code_to_wild_card(status_code)
        if (res = response[wild_card])
          return res
        end

        default
      end

      # parse 400 -> 4xx
      # OpenAPI3 allow 1xx, 2xx, 3xx... only, don't allow 41x
      # @param [Integer] status_code
      def status_code_to_wild_card(status_code)
        top = status_code / 100
        "#{top}XX"
      end
  end
end
