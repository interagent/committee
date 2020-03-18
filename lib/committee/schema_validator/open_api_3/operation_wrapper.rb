# frozen_string_literal: true

module Committee
  module SchemaValidator
    class OpenAPI3
      class OperationWrapper
        # # @param request_operation [OpenAPIParser::RequestOperation]
        def initialize(request_operation)
          @request_operation = request_operation
        end

        def path_params
          request_operation.path_params
        end

        def original_path
          request_operation.original_path
        end

        def coerce_path_parameter(validator_option)
          options = build_openapi_parser_path_option(validator_option)
          return {} unless options.coerce_value

          request_operation.validate_path_params(options)
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidRequest.new(e.message)
        end

        # @param [Boolean] strict when not content_type or status code definition, raise error
        def validate_response_params(status_code, headers, response_data, strict, check_header)
          response_body = OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, response_data, headers)

          return request_operation.validate_response_body(response_body, response_validate_options(strict, check_header))
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidResponse.new(e.message)
        end

        def validate_request_params(params, headers, validator_option)
          ret, err = case request_operation.http_method
                when 'get'
                  validate_get_request_params(params, headers, validator_option)
                when 'post'
                  validate_post_request_params(params, headers, validator_option)
                when 'put'
                  validate_post_request_params(params, headers, validator_option)
                when 'patch'
                  validate_post_request_params(params, headers, validator_option)
                when 'delete'
                  validate_get_request_params(params, headers, validator_option)
                else
                  raise "Committee OpenAPI3 not support #{request_operation.http_method} method"
                end
          raise err if err
          ret
        end

        def valid_request_content_type?(content_type)
          if (request_body = request_operation.operation_object&.request_body)
            !request_body.select_media_type(content_type).nil?
          else
            # if not exist request body object, all content_type allow.
            # because request body object required content field so when it exists there're content type definition.
            true
          end
        end

        def request_content_types
          request_operation.operation_object&.request_body&.content&.keys || []
        end

        private

        attr_reader :request_operation

        # @!attribute [r] request_operation
        #   @return [OpenAPIParser::RequestOperation]

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_path_option(validator_option)
          coerce_value = validator_option.coerce_path_params
          datetime_coerce_class = validator_option.coerce_date_times ? DateTime : nil
          validate_header = validator_option.check_header
          OpenAPIParser::SchemaValidator::Options.new(coerce_value: coerce_value,
                                                      datetime_coerce_class: datetime_coerce_class,
                                                      validate_header: validate_header)
        end

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_post_option(validator_option)
          coerce_value = validator_option.coerce_form_params
          datetime_coerce_class = validator_option.coerce_date_times ? DateTime : nil
          validate_header = validator_option.check_header
          OpenAPIParser::SchemaValidator::Options.new(coerce_value: coerce_value,
                                                      datetime_coerce_class: datetime_coerce_class,
                                                      validate_header: validate_header)
        end

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_get_option(validator_option)
          coerce_value = validator_option.coerce_query_params
          datetime_coerce_class = validator_option.coerce_date_times ? DateTime : nil
          validate_header = validator_option.check_header
          OpenAPIParser::SchemaValidator::Options.new(coerce_value: coerce_value,
                                                      datetime_coerce_class: datetime_coerce_class,
                                                      validate_header: validate_header)
        end

        def validate_get_request_params(params, headers, validator_option)
          # bad performance because when we coerce value, same check
          request_params = (params['path'] || {}).merge(params['query'] || {}).merge(params['body'] || {}).merge(params['form_data'] || {})
          result = request_operation.validate_request_parameter(request_params, headers, build_openapi_parser_get_option(validator_option))
          # Copy coerced params
          params['path'] = (params['path'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          params['query'] = (params['query'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          params['body'] = (params['body'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          params['form_data'] = (params['form_data'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          result
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidRequest.new(e.message)
        end

        def validate_post_request_params(params, headers, validator_option)
          content_type = headers['Content-Type'].to_s.split(";").first.to_s

          # bad performance because when we coerce value, same check
          schema_validator_options = build_openapi_parser_post_option(validator_option)
          request_params = (params['path'] || {}).merge(params['query'] || {}).merge(params['body'] || {}).merge(params['form_data'] || {})
          request_operation.validate_request_parameter(request_params, headers, schema_validator_options)
          result = request_operation.validate_request_body(content_type, params['body'], schema_validator_options)
          # Copy coerced params
          params['path'] = (params['path'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          params['query'] = (params['query'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          params['body'] = (params['body'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          params['form_data'] = (params['form_data'] || {}).keys.map { |k| [k, request_params[k]] }.to_h
          result
        rescue => e
          raise Committee::InvalidRequest.new(e.message)
        end

        def response_validate_options(strict, check_header)
          ::OpenAPIParser::SchemaValidator::ResponseValidateOptions.new(strict: strict, validate_header: check_header)
        end
      end
    end
  end
end
