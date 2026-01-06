# frozen_string_literal: true

module Committee
  module Middleware
    module Options
      class RequestValidation < Base
        # RequestValidation specific options
        attr_reader :strict
        attr_reader :coerce_date_times
        attr_reader :coerce_recursive
        attr_reader :coerce_form_params
        attr_reader :coerce_path_params
        attr_reader :coerce_query_params
        attr_reader :allow_form_params
        attr_reader :allow_query_params
        attr_reader :allow_get_body
        attr_reader :allow_non_get_query_params
        attr_reader :check_content_type
        attr_reader :check_header
        attr_reader :optimistic_json
        attr_reader :request_body_hash_key
        attr_reader :query_hash_key
        attr_reader :path_hash_key
        attr_reader :headers_key
        attr_reader :params_key
        attr_reader :allow_blank_structures
        attr_reader :allow_empty_date_and_datetime
        attr_reader :parameter_overwrite_by_rails_rule
        attr_reader :deserialize_parameters

        # Default values
        DEFAULTS = { strict: false, coerce_recursive: true, allow_get_body: false, check_content_type: true, check_header: true, optimistic_json: false, allow_form_params: true, allow_query_params: true, allow_non_get_query_params: false, allow_blank_structures: false, allow_empty_date_and_datetime: false, parameter_overwrite_by_rails_rule: true, request_body_hash_key: "committee.request_body_hash", query_hash_key: "committee.query_hash", path_hash_key: "committee.path_hash", headers_key: "committee.headers", params_key: "committee.params" }.freeze

        def initialize(options = {})
          super(options)

          # Validation related
          @strict = options.fetch(:strict, DEFAULTS[:strict])
          @check_content_type = options.fetch(:check_content_type, DEFAULTS[:check_content_type])
          @check_header = options.fetch(:check_header, DEFAULTS[:check_header])
          @optimistic_json = options.fetch(:optimistic_json, DEFAULTS[:optimistic_json])

          # Type coercion related
          @coerce_date_times = options[:coerce_date_times]
          @coerce_recursive = options.fetch(:coerce_recursive, DEFAULTS[:coerce_recursive])
          @coerce_form_params = options[:coerce_form_params]
          @coerce_path_params = options[:coerce_path_params]
          @coerce_query_params = options[:coerce_query_params]

          # Parameter permission related
          @allow_form_params = options.fetch(:allow_form_params, DEFAULTS[:allow_form_params])
          @allow_query_params = options.fetch(:allow_query_params, DEFAULTS[:allow_query_params])
          @allow_get_body = options.fetch(:allow_get_body, DEFAULTS[:allow_get_body])
          @allow_non_get_query_params = options.fetch(:allow_non_get_query_params, DEFAULTS[:allow_non_get_query_params])
          @allow_blank_structures = options.fetch(:allow_blank_structures, DEFAULTS[:allow_blank_structures])
          @allow_empty_date_and_datetime = options.fetch(:allow_empty_date_and_datetime, DEFAULTS[:allow_empty_date_and_datetime])

          # Rails compatibility
          @parameter_overwrite_by_rails_rule = options.fetch(:parameter_overwrite_by_rails_rule, DEFAULTS[:parameter_overwrite_by_rails_rule])

          # Deserialization
          @deserialize_parameters = options[:deserialize_parameters]

          # Hash keys
          @request_body_hash_key = options.fetch(:request_body_hash_key, DEFAULTS[:request_body_hash_key])
          @query_hash_key = options.fetch(:query_hash_key, DEFAULTS[:query_hash_key])
          @path_hash_key = options.fetch(:path_hash_key, DEFAULTS[:path_hash_key])
          @headers_key = options.fetch(:headers_key, DEFAULTS[:headers_key])
          @params_key = options.fetch(:params_key, DEFAULTS[:params_key])
        end

        private

        def build_hash
          super.merge(strict: @strict, coerce_date_times: @coerce_date_times, coerce_recursive: @coerce_recursive, coerce_form_params: @coerce_form_params, coerce_path_params: @coerce_path_params, coerce_query_params: @coerce_query_params, allow_form_params: @allow_form_params, allow_query_params: @allow_query_params, allow_get_body: @allow_get_body, allow_non_get_query_params: @allow_non_get_query_params, allow_blank_structures: @allow_blank_structures, allow_empty_date_and_datetime: @allow_empty_date_and_datetime, parameter_overwrite_by_rails_rule: @parameter_overwrite_by_rails_rule, deserialize_parameters: @deserialize_parameters, check_content_type: @check_content_type, check_header: @check_header, optimistic_json: @optimistic_json, request_body_hash_key: @request_body_hash_key, query_hash_key: @query_hash_key, path_hash_key: @path_hash_key, headers_key: @headers_key, params_key: @params_key)
        end
      end
    end
  end
end
