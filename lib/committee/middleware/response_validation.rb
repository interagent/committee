module Committee::Middleware
  class ResponseValidation < Base
    attr_reader :validate_errors

    def initialize(app, options = {})
      super
      @validate_errors = options[:validate_errors]
    end

    def handle(request)
      status, headers, response = @app.call(request.env)

      build_schema_validator(request).response_validate(status, headers, response) if validate?(status)

      [status, headers, response]
    rescue Committee::InvalidResponse
      raise if @raise
      @error_class.new(500, :invalid_response, $!.message).render
    rescue JSON::ParserError
      raise Committee::InvalidResponse if @raise
      @error_class.new(500, :invalid_response, "Response wasn't valid JSON.").render
    end

    def validate?(status)
      status != 204 and validate_errors || (200...300).include?(status)
    end
  end
end
