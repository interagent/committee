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
          validated_path_params = request_operation.validate_path_params(options)
          return {} unless options.coerce_value

          validated_path_params
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidRequest.new(e.message, original_error: e)
        end

        # @param [Boolean] strict when not content_type or status code definition, raise error
        def validate_response_params(status_code, headers, response_data, strict, check_header, strict_response_content_type: false, validator_options: {})
          response_body = OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, response_data, headers)

          # When strict_response_content_type is enabled, reject responses whose Content-Type is not
          # declared in the spec's content map for this status code. Responses with no content map
          # (e.g. bare 204s) are skipped — openapi_parser's validate_response_body handles those.
          if strict_response_content_type
            response_object = find_response_object_for_status(request_operation.operation_object&.responses, status_code)
            if response_object
              content_type = Rack::MediaType.type(response_body.content_type)
              matched = response_object.select_media_type(content_type)
              if matched.nil? && response_object.content && !response_object.content.empty?
                raise Committee::InvalidResponse, "Response Content-Type '#{content_type}' is not declared in the OpenAPI spec for this operation. Declared types: #{response_object.content.keys.join(', ')}"
              end
            end
          end

          return request_operation.validate_response_body(response_body, response_validate_options(strict, check_header, validator_options: validator_options))
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

        def optional_body?
          !request_operation.operation_object&.request_body&.required
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

        # Expose request_operation for parameter deserialization
        # @return [OpenAPIParser::RequestOperation]
        attr_reader :request_operation

        # @return [Array<String>] names of query parameters defined in the schema
        def query_parameter_names
          return [] unless request_operation.operation_object&.parameters

          request_operation.operation_object.parameters.select { |p| p.in == 'query' }.map(&:name)
        end

        private

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_body_option(validator_option)
          build_openapi_parser_option(validator_option, validator_option.coerce_form_params)
        end

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_path_option(validator_option)
          build_openapi_parser_option(validator_option, validator_option.coerce_path_params)
        end

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_request_parameter_option(validator_option)
          build_openapi_parser_option(validator_option, validator_option.coerce_query_params)
        end

        # @return [OpenAPIParser::SchemaValidator::Options]
        def build_openapi_parser_option(validator_option, coerce_value)
          parser_options = {
            coerce_value: coerce_value,
            datetime_coerce_class: validator_option.coerce_date_times ? DateTime : nil,
            validate_header: validator_option.check_header,
          }
          if OpenAPIParser::SchemaValidator::Options.method_defined?(:allow_empty_date_and_datetime)
            parser_options[:allow_empty_date_and_datetime] = validator_option.allow_empty_date_and_datetime
          end
          OpenAPIParser::SchemaValidator::Options.new(**parser_options)
        end

        def validate_get_request_params(path_params, query_params, headers, validator_option)
          # bad performance because when we coerce value, same check
          validate_path_and_query_params(path_params, query_params, headers, validator_option)
        rescue OpenAPIParser::OpenAPIError => e
          raise Committee::InvalidRequest.new(e.message, original_error: e)
        end

        def validate_post_request_params(path_params, query_params, body_params, headers, validator_option)
          content_type_key = headers.keys.detect { |k| k.casecmp?('Content-Type') }
          content_type = Rack::MediaType.type(headers[content_type_key])

          # bad performance because when we coerce value, same check
          validate_path_and_query_params(path_params, query_params, headers, validator_option)
          request_operation.validate_request_body(content_type, body_params, build_openapi_parser_body_option(validator_option))
        rescue => e
          raise Committee::InvalidRequest.new(e.message, original_error: e)
        end

        def validate_path_and_query_params(path_params, query_params, headers, validator_option)
          path_params ||= {}
          query_params ||= {}

          # it's currently impossible to validate path params and query params separately
          # so we have to resort to this workaround

          path_keys = path_params.keys.to_set
          query_keys = query_params.keys.to_set

          merged_params = query_params.merge(path_params)

          request_operation.validate_request_parameter(merged_params, headers, build_openapi_parser_request_parameter_option(validator_option))

          merged_params.each do |k, v|
            path_params[k] = v if path_keys.include?(k)
            query_params[k] = v if query_keys.include?(k)
          end

          validate_no_unknown_query_params(query_params) if validator_option.strict_query_params
        end

        def validate_no_unknown_query_params(query_params)
          return if query_params.nil? || query_params.empty?

          defined_params = query_parameter_names
          unknown_params = query_params.keys - defined_params

          return if unknown_params.empty?

          raise Committee::InvalidRequest.new("Unknown query parameter(s): #{unknown_params.join(', ')}")
        end

        def find_response_object_for_status(responses, status_code)
          return nil unless responses&.response

          response_hash = responses.response
          return response_hash[status_code.to_s] if response_hash[status_code.to_s]

          wild_card = "#{status_code.to_i / 100}XX"
          return response_hash[wild_card] if response_hash[wild_card]

          responses.default
        end

        def response_validate_options(strict, check_header, validator_options: {})
          options = { strict: strict, validate_header: check_header }

          if validator_options[:coerce_value]
            options[:coerce_value] = validator_options[:coerce_value]
          end

          if validator_options[:allow_empty_date_and_datetime]
            options[:allow_empty_date_and_datetime] = validator_options[:allow_empty_date_and_datetime]
          end

          ::OpenAPIParser::SchemaValidator::ResponseValidateOptions.new(**options)
        end
      end
    end
  end
end
