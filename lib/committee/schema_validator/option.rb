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
                  :validate_success_only

      # Non-boolean options:
      attr_reader :headers_key,
                  :params_key,
                  :prefix

      def initialize(options, schema, schema_type)
        # Non-boolean options
        @headers_key         = options[:headers_key] || "committee.headers"
        @params_key          = options[:params_key] || "committee.params"
        @prefix              = options[:prefix]

        # Boolean options and have a common value by default
        @allow_form_params   = options.fetch(:allow_form_params, true)
        @allow_query_params  = options.fetch(:allow_query_params, true)
        @check_content_type  = options.fetch(:check_content_type, true)
        @check_header        = options.fetch(:check_header, true)
        @coerce_recursive    = options.fetch(:coerce_recursive, true)
        @optimistic_json     = options.fetch(:optimistic_json, false)

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
