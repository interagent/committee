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

    def validate_request_body(content_type, params, options)
      request_body&.validate_request_body(content_type, params, options)
    end

    def validate_response_body(status_code, content_type, data)
      responses&.validate_response_body(status_code, content_type, data)
    end

    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_request_parameter(params, options)
      OpenAPIParser::ParameterValidator.validate_parameter(query_parameter_hash, params, object_reference, options)
    end

    def validate_path_params(path_params, options)
      OpenAPIParser::ParameterValidator.validate_parameter(path_parameter_hash, path_params, object_reference, options)
    end

    private

      def path_parameter_hash
        @path_parameter_hash ||= (parameters || []).
                                   select(&:in_path?).
                                   map { |param| [param.name, param] }.
                                   to_h
      end

      def query_parameter_hash
        @query_parameter_hash ||= (parameters || []).
                                    select(&:in_query?).
                                    map { |param| [param.name, param] }.
                                    to_h
      end
  end
end
