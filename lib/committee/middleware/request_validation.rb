module Committee::Middleware
  class RequestValidation < Base
    def initialize(app, options={})
      super

      @allow_form_params   = options.fetch(:allow_form_params, true)
      @allow_query_params  = options.fetch(:allow_query_params, true)
      @check_content_type  = options.fetch(:check_content_type, true)
      @optimistic_json     = options.fetch(:optimistic_json, false)
      @strict              = options[:strict]

      @coerce_path_params = options.fetch(:coerce_path_params,
        @schema.driver.default_path_params)
      @coerce_query_params = options.fetch(:coerce_query_params,
        @schema.driver.default_query_params)

      # deprecated
      @allow_extra = options[:allow_extra]
    end

    def handle(request)
      schema_validator = build_schema_validator(request)

      # Attempts to coerce parameters that appear in a link's URL to Ruby
      # types that can be validated with a schema.
      path_params = @coerce_path_params ? schema_validator.coerce_path_params : {}

      # Attempts to coerce parameters that appear in a query string to Ruby
      # types that can be validated with a schema.
      schema_validator.coerce_query_params(request) if @coerce_query_params

      request.env[@params_key] = Committee::RequestUnpacker.new(
        request,
        allow_form_params:  @allow_form_params,
        allow_query_params: @allow_query_params,
        optimistic_json:    @optimistic_json
      ).call

      request.env[@params_key].merge!(path_params)

      raise Committee::NotFound if @strict && !schema_validator.link_exist?

      schema_validator.validate_request(request, @params_key, @check_content_type)

      @app.call(request.env)
    rescue Committee::BadRequest, Committee::InvalidRequest
      raise if @raise
      @error_class.new(400, :bad_request, $!.message).render
    rescue Committee::NotFound
      raise if @raise
      @error_class.new(
        404,
        :not_found,
        "That request method and path combination isn't defined."
      ).render
    rescue JSON::ParserError
      raise Committee::InvalidRequest if @raise
      @error_class.new(400, :bad_request, "Request body wasn't valid JSON.").render
    end

    def build_schema_validator(request)
      Committee::SchemaValidator::HyperSchema.new(@router, request)
    end
  end
end
