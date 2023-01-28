# frozen_string_literal: true

module Committee
  module SchemaValidator
    class Option
      # Boolean Options
      attr_reader :allow_form_params,
                  :allow_get_body,
                  :allow_query_params,
                  :check_content_type,
                  :check_header,
                  :coerce_date_times,
                  :coerce_form_params,
                  :coerce_path_params,
                  :coerce_query_params,
                  :coerce_recursive,
                  :optimistic_json,
                  :validate_success_only,
                  :parse_response_by_content_type,
                  :parameter_overwite_by_rails_rule

      # Non-boolean options:
      attr_reader :headers_key,
                  :params_key,
                  :query_hash_key,
                  :request_body_hash_key,
                  :path_hash_key,
                  :prefix

      def initialize(options, schema, schema_type)
        # Non-boolean options
        @headers_key         = options[:headers_key]    || "committee.headers"
        @params_key          = options[:params_key]     || "committee.params"
        @query_hash_key      = options[:query_hash_key] || "committee.query_hash"
        @path_hash_key      = options[:path_hash_key] || "committee.path_hash"
        @request_body_hash_key = options[:request_body_hash_key] || "committee.request_body_hash"

        @prefix              = options[:prefix]

        # Boolean options and have a common value by default
        @allow_form_params   = options.fetch(:allow_form_params, true)
        @allow_query_params  = options.fetch(:allow_query_params, true)
        @check_content_type  = options.fetch(:check_content_type, true)
        @check_header        = options.fetch(:check_header, true)
        @coerce_recursive    = options.fetch(:coerce_recursive, true)
        @optimistic_json     = options.fetch(:optimistic_json, false)
        @parse_response_by_content_type = options.fetch(:parse_response_by_content_type, true)
        @parameter_overwite_by_rails_rule = options.fetch(:parameter_overwite_by_rails_rule, true)

        # Boolean options and have a different value by default
        @allow_get_body      = options.fetch(:allow_get_body, schema.driver.default_allow_get_body)
        @coerce_date_times   = options.fetch(:coerce_date_times, schema.driver.default_coerce_date_times)
        @coerce_form_params  = options.fetch(:coerce_form_params, schema.driver.default_coerce_form_params)
        @coerce_path_params  = options.fetch(:coerce_path_params, schema.driver.default_path_params)
        @coerce_query_params = options.fetch(:coerce_query_params, schema.driver.default_query_params)
        @validate_success_only = options.fetch(:validate_success_only, schema.driver.default_validate_success_only)
      end
    end
  end
end
