# TODO: externalDocs
# TODO: callbacks
# TODO: security
# TODO: servers

module OpenAPIParser::Schemas
  class Operation < Base
    include OpenAPIParser::ParameterValidatable

    openapi_attr_values :tags, :summary, :description, :deprecated

    openapi_attr_value :operation_id, schema_key: :operationId

    openapi_attr_list_object :parameters, Parameter, reference: true

    # @!attribute [r] request_body
    #   @return [OpenAPIParser::Schemas::RequestBody, nil] return OpenAPI3 object
    openapi_attr_object :request_body, RequestBody, reference: true, schema_key: :requestBody

    # @!attribute [r] responses
    #   @return [OpenAPIParser::Schemas::Responses, nil] return OpenAPI3 object
    openapi_attr_object :responses, Responses, reference: false

    def validate_request_body(content_type, params, options)
      request_body&.validate_request_body(content_type, params, options)
    end

    # @param [OpenAPIParser::RequestOperation::ValidatableResponseBody] response_body
    # @param [OpenAPIParser::SchemaValidator::ResponseValidateOptions] response_validate_options
    def validate_response(response_body, response_validate_options)
      responses&.validate(response_body, response_validate_options)
    end
  end
end
