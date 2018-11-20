class Committee::SchemaValidator
  class Option
    attr_reader :coerce_recursive, :params_key, :allow_form_params, :allow_query_params, :optimistic_json, :coerce_form_params, :headers_key, :coerce_query_params, :coerce_path_params, :check_content_type, :check_header, :coerce_date_times, :validate_errors, :prefix

    def initialize(options, schema, schema_type)
      @schema_type = schema_type
      @headers_key = options[:headers_key] || "committee.headers"
      @params_key = options[:params_key] || "committee.params"

      @coerce_recursive = options.fetch(:coerce_recursive, true)

      @allow_form_params   = options.fetch(:allow_form_params, true)
      @allow_query_params  = options.fetch(:allow_query_params, true)
      @optimistic_json     = options.fetch(:optimistic_json, false)

      @coerce_form_params = options.fetch(:coerce_form_params,
                                          schema.driver.default_coerce_form_params)

      @coerce_query_params = options.fetch(:coerce_query_params, schema.driver.default_query_params)

      @coerce_path_params = options.fetch(:coerce_path_params,
                                          schema.driver.default_path_params)

      raise 'OpenAPI3 not support @check_content_type option' if schema_type == :open_api_3 && options[:check_content_type]
      @check_content_type  = options.fetch(:check_content_type, true)

      raise 'OpenAPI3 not support @check_header option' if schema_type == :open_api_3 && options[:check_header]
      @check_header        = options.fetch(:check_header, true)

      raise 'OpenAPI3 not support @coerce_date_times option' if schema_type == :open_api_3 && options[:coerce_date_times]
      @coerce_date_times   = options.fetch(:coerce_date_times, false)

      @prefix = options[:prefix]

      # response option
      @validate_errors = options[:validate_errors]
    end
  end
end