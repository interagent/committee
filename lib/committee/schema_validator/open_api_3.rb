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
        path_params = validator_option.coerce_path_params ? coerce_path_params : {}

        request_unpack(request)

        request.env[validator_option.params_key]&.merge!(path_params) unless path_params.empty?

        request_schema_validation(request)

        copy_coerced_data_to_query_hash(request)
      end

      def response_validate(status, headers, response, test_method = false)
        full_body = +""
        response.each do |chunk|
          full_body << chunk
        end
        data = full_body.empty? ? {} : JSON.parse(full_body)

        strict = test_method
        Committee::SchemaValidator::OpenAPI3::ResponseValidator.
            new(@operation_object, validator_option).
            call(status, headers, data, strict)
      end

      def link_exist?
        !@operation_object.nil?
      end

      def coerce_form_params(_parameter)
        # Empty because request_schema_validation checks and coerces
      end

      private

      attr_reader :validator_option

      def coerce_path_params
        return {} unless link_exist?
        @operation_object.coerce_path_parameter(@validator_option)
      end

      def request_schema_validation(request)
        return unless @operation_object

        validator = Committee::SchemaValidator::OpenAPI3::RequestValidator.new(@operation_object, validator_option: validator_option)
        validator.call(request, request.env[validator_option.params_key], header(request))
      end

      def header(request)
        request.env[validator_option.headers_key]
      end

      def request_unpack(request)
        request.env[validator_option.params_key], request.env[validator_option.headers_key] = Committee::RequestUnpacker.new(
            request,
            allow_form_params:  validator_option.allow_form_params,
            allow_get_body:     validator_option.allow_get_body,
            allow_query_params: validator_option.allow_query_params,
            coerce_form_params: validator_option.coerce_form_params,
            optimistic_json:    validator_option.optimistic_json,
            schema_validator:   self
        ).call
      end

      def copy_coerced_data_to_query_hash(request)
        return if request.env["rack.request.query_hash"].nil? || request.env["rack.request.query_hash"].empty?

        request.env["rack.request.query_hash"].keys.each do |k|
          request.env["rack.request.query_hash"][k] = request.env[validator_option.params_key][k]
        end
      end
    end
  end
end

require_relative "open_api_3/router"
require_relative "open_api_3/operation_wrapper"
require_relative "open_api_3/request_validator"
require_relative "open_api_3/response_validator"
