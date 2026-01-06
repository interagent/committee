# frozen_string_literal: true

module Committee
  module SchemaValidator
    class Option
      # Boolean Options
      attr_reader :allow_blank_structures, :allow_empty_date_and_datetime, :allow_form_params, :allow_get_body, :allow_query_params, :allow_non_get_query_params, :check_content_type, :check_header, :coerce_date_times, :coerce_form_params, :coerce_path_params, :coerce_query_params, :coerce_recursive, :coerce_response_values, :deserialize_parameters, :optimistic_json, :validate_success_only, :parse_response_by_content_type, :parameter_overwrite_by_rails_rule, :strict_query_params

      # Non-boolean options:
      attr_reader :headers_key, :params_key, :query_hash_key, :request_body_hash_key, :path_hash_key, :prefix

      def initialize(options, schema, schema_type)
        # Non-boolean options
        @headers_key           = options[:headers_key]    || "committee.headers"
        @params_key            = options[:params_key]     || "committee.params"
        @query_hash_key        = options[:query_hash_key] || "committee.query_hash"
        @path_hash_key         = options[:path_hash_key] || "committee.path_hash"
        @request_body_hash_key = options[:request_body_hash_key] || "committee.request_body_hash"

        @prefix                = options[:prefix]

        # Boolean options and have a common value by default
        @allow_blank_structures           = options.fetch(:allow_blank_structures, false)
        @allow_empty_date_and_datetime    = options.fetch(:allow_empty_date_and_datetime, false)
        @allow_form_params                = options.fetch(:allow_form_params, true)
        @allow_query_params               = options.fetch(:allow_query_params, true)
        @allow_non_get_query_params       = options.fetch(:allow_non_get_query_params, false)
        @check_content_type               = options.fetch(:check_content_type, true)
        @check_header                     = options.fetch(:check_header, true)
        @coerce_recursive                 = options.fetch(:coerce_recursive, true)
        @coerce_response_values           = options.fetch(:coerce_response_values, false)
        @optimistic_json                  = options.fetch(:optimistic_json, false)
        @parse_response_by_content_type   = options.fetch(:parse_response_by_content_type, true)
        @strict_query_params              = options.fetch(:strict_query_params, false)

        @parameter_overwrite_by_rails_rule =
          if options.key?(:parameter_overwite_by_rails_rule)
            Committee.warn_deprecated_until_6(true, "The option `parameter_overwite_by_rails_rule` is deprecated. Use `parameter_overwrite_by_rails_rule` instead.")
            options[:parameter_overwite_by_rails_rule]
          else
            options.fetch(:parameter_overwrite_by_rails_rule, true)
          end

        # Boolean options and have a different value by default
        @allow_get_body        = options.fetch(:allow_get_body, schema.driver.default_allow_get_body)
        @coerce_date_times     = options.fetch(:coerce_date_times, schema.driver.default_coerce_date_times)
        @coerce_form_params    = options.fetch(:coerce_form_params, schema.driver.default_coerce_form_params)
        @coerce_path_params    = options.fetch(:coerce_path_params, schema.driver.default_path_params)
        @coerce_query_params   = options.fetch(:coerce_query_params, schema.driver.default_query_params)
        @deserialize_parameters = options.fetch(:deserialize_parameters,
                                                 schema.driver.respond_to?(:default_deserialize_parameters) ?
                                                   schema.driver.default_deserialize_parameters : false)
        @validate_success_only = options.fetch(:validate_success_only, schema.driver.default_validate_success_only)
      end
    end
  end
end
