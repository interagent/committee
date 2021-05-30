# frozen_string_literal: true

module Committee
  module SchemaValidator
    class HyperSchema
      attr_reader :link, :param_matches, :validator_option

      def initialize(router, request, validator_option)
        @link, @param_matches = router.find_request_link(request)
        @validator_option = validator_option
      end

      def request_validate(request)
        request_unpack(request)

        request_schema_validation(request)
        parameter_coerce!(request, link, validator_option.params_key)
        parameter_coerce!(request, link, "rack.request.query_hash") if link_exist? && !request.GET.nil? && !link.schema.nil?
      end

      def response_validate(status, headers, response, _test_method = false)
        return unless link_exist?

        full_body = +""
        response.each do |chunk|
          full_body << chunk
        end

        data = {}
        unless full_body.empty?
          parse_to_json = !validator_option.parse_response_by_content_type ||
                          headers.fetch('Content-Type', nil)&.start_with?('application/json')
          data = JSON.parse(full_body) if parse_to_json
        end

        Committee::SchemaValidator::HyperSchema::ResponseValidator.new(link, validate_success_only: validator_option.validate_success_only).call(status, headers, data)
      end

      def link_exist?
        !link.nil?
      end

      private

        def coerce_path_params
          return {} unless link_exist?

          Committee::SchemaValidator::HyperSchema::StringParamsCoercer.new(param_matches, link.schema, coerce_recursive: validator_option.coerce_recursive).call!
          param_matches
        end

        def coerce_query_params(request)
          return unless link_exist?
          return if request.GET.nil? || link.schema.nil?

          Committee::SchemaValidator::HyperSchema::StringParamsCoercer.new(request.GET, link.schema, coerce_recursive: validator_option.coerce_recursive).call!
        end

        def request_unpack(request)
          unpacker = Committee::RequestUnpacker.new(
            allow_form_params:  validator_option.allow_form_params,
            allow_get_body:     validator_option.allow_get_body,
            allow_query_params: validator_option.allow_query_params,
            optimistic_json:    validator_option.optimistic_json,
          )

          request.env[validator_option.headers_key] = unpacker.unpack_headers(request)

          # Attempts to coerce parameters that appear in a link's URL to Ruby
          # types that can be validated with a schema.
          param_matches_hash = validator_option.coerce_path_params ? coerce_path_params : {}

          # Attempts to coerce parameters that appear in a query string to Ruby
          # types that can be validated with a schema.
          coerce_query_params(request) if validator_option.coerce_query_params

          query_param = unpacker.unpack_query_params(request)
          request_param, is_form_params = unpacker.unpack_request_params(request)
          coerce_form_params(request_param) if validator_option.coerce_form_params && is_form_params
          request.env[validator_option.request_body_hash_key] = request_param

          request.env[validator_option.params_key] = Committee::Utils.indifferent_hash
          request.env[validator_option.params_key].merge!(Committee::Utils.deep_copy(query_param))
          request.env[validator_option.params_key].merge!(Committee::Utils.deep_copy(request_param))
          request.env[validator_option.params_key].merge!(Committee::Utils.deep_copy(param_matches_hash))
        end

        def coerce_form_params(parameter)
          return unless link_exist?
          return unless link.schema
          Committee::SchemaValidator::HyperSchema::StringParamsCoercer.new(parameter, link.schema).call!
        end

        def request_schema_validation(request)
          return unless link_exist?
          validator = Committee::SchemaValidator::HyperSchema::RequestValidator.new(link, check_content_type: validator_option.check_content_type, check_header: validator_option.check_header)
          validator.call(request, request.env[validator_option.params_key], request.env[validator_option.headers_key])
        end

        def parameter_coerce!(request, link, coerce_key)
          return unless link_exist?

          Committee::SchemaValidator::HyperSchema::ParameterCoercer.
              new(request.env[coerce_key],
                  link.schema,
                  coerce_date_times: validator_option.coerce_date_times,
                  coerce_recursive: validator_option.coerce_recursive).
              call!
        end
    end
  end
end

require_relative "hyper_schema/request_validator"
require_relative "hyper_schema/response_generator"
require_relative "hyper_schema/response_validator"
require_relative "hyper_schema/router"
require_relative "hyper_schema/string_params_coercer"
require_relative "hyper_schema/parameter_coercer"
