module Committee::Middleware
  class RequestValidation < Base
    def initialize(app, options={})
      super

      @strict  = options[:strict]

      # deprecated
      @allow_extra = options[:allow_extra]

      @validator_option = Committee::SchemaValidator::Option.new(@params_key, @headers_key, options, @schema)
    end

    def handle(request)
      schema_validator = build_schema_validator(request)
      schema_validator.call(request)

      raise Committee::NotFound, "That request method and path combination isn't defined." if !schema_validator.link_exist? && @strict

      @app.call(request.env)
    rescue Committee::BadRequest, Committee::InvalidRequest
      raise if @raise
      @error_class.new(400, :bad_request, $!.message).render
    rescue Committee::NotFound => e
      raise if @raise
      @error_class.new(
        404,
        :not_found,
        e.message
      ).render
    rescue JSON::ParserError
      raise Committee::InvalidRequest if @raise
      @error_class.new(400, :bad_request, "Request body wasn't valid JSON.").render
    end

    private
    
      def build_schema_validator(request)
        Committee::SchemaValidator::HyperSchema.new(@router, request, @validator_option)
      end
  end
end
