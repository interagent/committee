class Committee::SchemaValidator
  class Option
    attr_reader :coerce_recursive, :params_key,
                :allow_form_params, :allow_query_params,
                :optimistic_json,
                :coerce_form_params, :headers_key,
                :coerce_query_params, :coerce_path_params,
                :check_content_type, :check_header,
                :coerce_date_times, :prefix,
                :validate_success_only, :allow_get_body

    def initialize(options, schema, schema_type)
      @headers_key         = options[:headers_key] || "committee.headers"
      @params_key          = options[:params_key] || "committee.params"

      @prefix              = options[:prefix]

      # response option
      @validate_success_only = options.fetch(:validate_success_only, schema.driver.default_validate_success_only)

      @coerce_recursive    = options.fetch(:coerce_recursive, true)
      @allow_form_params   = options.fetch(:allow_form_params, true)
      @allow_query_params  = options.fetch(:allow_query_params, true)
      @optimistic_json     = options.fetch(:optimistic_json, false)

      @coerce_form_params  = options.fetch(:coerce_form_params, schema.driver.default_coerce_form_params)
      @coerce_date_times   = options.fetch(:coerce_date_times, schema.driver.default_coerce_date_times)
      @coerce_query_params = options.fetch(:coerce_query_params, schema.driver.default_query_params)
      @coerce_path_params  = options.fetch(:coerce_path_params, schema.driver.default_path_params)

      @check_content_type  = options.fetch(:check_content_type, true)
      @check_header        = options.fetch(:check_header, true)

      @allow_get_body      = options.fetch(:allow_get_body, schema.driver.default_allow_get_body)
    end
  end
end
