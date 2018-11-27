# TODO: externalDocs
# TODO: callbacks
# TODO: security
# TODO: servers

module OpenAPIParser::Schemas
  class Operation < Base
    openapi_attr_values :tags, :summary, :description, :deprecated

    openapi_attr_value :operation_id, schema_key: :operationId

    openapi_attr_list_object :parameters, Parameter, reference: true

    # @!attribute [r] request_body
    #   @return [OpenAPIParser::Schemas::RequestBody, nil]
    openapi_attr_object :request_body, RequestBody, reference: true, schema_key: :requestBody

    openapi_attr_object :responses, Responses, reference: false

    def validate_request_body(content_type, params)
      request_body&.validate_request_body(content_type, params)
    end
  end
end
