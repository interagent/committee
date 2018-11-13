class Committee::SchemaValidator
  class Option
    attr_reader :coerce_recursive, :params_key, :allow_form_params, :allow_query_params, :optimistic_json, :coerce_form_params, :headers_key, :coerce_query_params, :coerce_path_params, :check_content_type, :check_header, :coerce_date_times, :validate_errors, :prefix

    def initialize(options, schema)
      @headers_key = options[:headers_key] || "committee.headers"
      @params_key = options[:params_key] || "committee.params"

      @coerce_recursive = options.fetch(:coerce_recursive, true)

      @allow_form_params   = options.fetch(:allow_form_params, true)
      @allow_query_params  = options.fetch(:allow_query_params, true)
      @optimistic_json     = options.fetch(:optimistic_json, false)

      @coerce_form_params = options.fetch(:coerce_form_params,
                                          schema.driver.default_coerce_form_params)

      @coerce_query_params = options.fetch(:coerce_query_params,
                                           schema.driver.default_query_params)

      @coerce_path_params = options.fetch(:coerce_path_params,
                                          schema.driver.default_path_params)

      @check_content_type  = options.fetch(:check_content_type, true)
      @check_header        = options.fetch(:check_header, true)

      @coerce_date_times   = options.fetch(:coerce_date_times, false)

      @prefix = options[:prefix]

      # response option
      @validate_errors = options[:validate_errors]
    end
  end
end