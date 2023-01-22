# frozen_string_literal: true

module Committee
  module SchemaValidator
    class OpenAPI3
      # @param [Committee::SchemaValidator::Option] validator_option
      def initialize(router, request, validator_option)
        @router = router
        @request = request
        @operation_object = router.operation_object(request)
        @validator_option = validator_option
      end

      def request_validate(request)
        return unless link_exist?

        request_unpack(request)
        request_schema_validation(request)

        copy_coerced_data_to_params(request)
      end

      def response_validate(status, headers, response, test_method = false)
        full_body = +""
        response.each do |chunk|
          full_body << chunk
        end

        parse_to_json = !validator_option.parse_response_by_content_type || 
                        headers.fetch('Content-Type', nil)&.start_with?('application/json')
        data = if parse_to_json
          full_body.empty? ? {} : JSON.parse(full_body)
        else
          full_body
        end

        # TODO: refactoring name
        strict = test_method
        Committee::SchemaValidator::OpenAPI3::ResponseValidator.
            new(@operation_object, validator_option).
            call(status, headers, data, strict)
      end

      def link_exist?
        !@operation_object.nil?
      end

      private

      attr_reader :validator_option

      def coerce_path_params
        return Committee::Utils.indifferent_hash unless validator_option.coerce_path_params
        Committee::RequestUnpacker.indifferent_params(@operation_object.coerce_path_parameter(@validator_option))
      end

      def request_schema_validation(request)
        return unless @operation_object

        validator = Committee::SchemaValidator::OpenAPI3::RequestValidator.new(@operation_object, validator_option: validator_option)
        validator.call(request, path_params(request), query_params(request), body_params(request), header(request))
      end

      def path_params(request)
        request.env[validator_option.path_hash_key]
      end

      def query_params(request)
        request.env[validator_option.query_hash_key]
      end

      def body_params(request)
        request.env[validator_option.request_body_hash_key]
      end

      def header(request)
        request.env[validator_option.headers_key]
      end

      def request_unpack(request)
        unpacker = Committee::RequestUnpacker.new(
          allow_form_params:  validator_option.allow_form_params,
          allow_get_body:     validator_option.allow_get_body,
          allow_query_params: validator_option.allow_query_params,
          optimistic_json:    validator_option.optimistic_json,
        )

        request.env[validator_option.headers_key] = unpacker.unpack_headers(request)

        request_param, is_form_params = unpacker.unpack_request_params(request)
        request.env[validator_option.request_body_hash_key] = request_param
        request.env[validator_option.path_hash_key] = coerce_path_params

        query_param = unpacker.unpack_query_params(request)
        query_param.merge!(request_param) if request.get? && validator_option.allow_get_body
        request.env[validator_option.query_hash_key] = query_param
      end

      def copy_coerced_data_to_params(request)
        request.env[validator_option.params_key] = Committee::Utils.indifferent_hash
        request.env[validator_option.params_key].merge!(Committee::Utils.deep_copy(request.env[validator_option.request_body_hash_key]))
        request.env[validator_option.params_key].merge!(Committee::Utils.deep_copy(request.env[validator_option.query_hash_key]))
        request.env[validator_option.params_key].merge!(Committee::Utils.deep_copy(request.env[validator_option.path_hash_key]))
      end
    end
  end
end

require_relative "open_api_3/router"
require_relative "open_api_3/operation_wrapper"
require_relative "open_api_3/request_validator"
require_relative "open_api_3/response_validator"
