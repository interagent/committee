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

        def http_method
          request_operation.http_method
        end

        def coerce_path_parameter(validator_option)
          options = build_openapi_parser_path_option(validator_option)
          return {} unless options.coerce_value

          request_operation.validate_path_params(options)
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidRequest.new(e.message, original_error: e)
        end

        # @param [Boolean] strict when not content_type or status code definition, raise error
        def validate_response_params(status_code, headers, response_data, strict, check_header)
          response_body = OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, response_data, headers)

          return request_operation.validate_response_body(response_body, response_validate_options(strict, check_header))
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidResponse.new(e.message, original_error: e)
        end

        def validate_request_params(path_params, query_params, body_params, headers, validator_option)
          ret, err = case request_operation.http_method
                when 'get', 'delete', 'head'
                  validate_get_request_params(path_params, query_params, headers, validator_option)
                when 'post', 'put', 'patch', 'options'
                  validate_post_request_params(path_params, query_params, body_params, headers, validator_option)
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
        def build_openapi_parser_body_option(validator_option)
          build_openapi_parser_option(validator_option, validator_option.coerce_form_params)
        end

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_path_option(validator_option)
          build_openapi_parser_option(validator_option, validator_option.coerce_query_params)
        end

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_option(validator_option, coerce_value)
          datetime_coerce_class = validator_option.coerce_date_times ? DateTime : nil
          validate_header = validator_option.check_header
          OpenAPIParser::SchemaValidator::Options.new(coerce_value: coerce_value,
                                                      datetime_coerce_class: datetime_coerce_class,
                                                      validate_header: validate_header)
        end

        def validate_get_request_params(path_params, query_params, headers, validator_option)
          # bad performance because when we coerce value, same check
          validate_path_and_query_params(path_params, query_params, headers, validator_option)
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidRequest.new(e.message, original_error: e)
        end

        def validate_post_request_params(path_params, query_params, body_params, headers, validator_option)
          content_type = headers['Content-Type'].to_s.split(";").first.to_s

          # bad performance because when we coerce value, same check
          validate_path_and_query_params(path_params, query_params, headers, validator_option)
          request_operation.validate_request_body(content_type, body_params, build_openapi_parser_body_option(validator_option))
        rescue => e
          raise Committee::InvalidRequest.new(e.message, original_error: e)
        end

        def validate_path_and_query_params(path_params, query_params, headers, validator_option)
          # it's currently impossible to validate path params and query params separately
          # so we have to resort to this workaround

          path_keys = path_params.keys.to_set
          query_keys = query_params.keys.to_set

          merged_params = query_params.merge(path_params)

          request_operation.validate_request_parameter(merged_params, headers, build_openapi_parser_path_option(validator_option))

          merged_params.each do |k, v|
            path_params[k] = v if path_keys.include?(k)
            query_params[k] = v if query_keys.include?(k)
          end
        end

        def response_validate_options(strict, check_header)
          ::OpenAPIParser::SchemaValidator::ResponseValidateOptions.new(strict: strict, validate_header: check_header)
        end
      end
    end
  end
end
