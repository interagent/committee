module Committee::Middleware
  class ResponseValidation < Base
    attr_reader :validate_errors

    def initialize(app, options = {})
      super
      @validate_errors = options[:validate_errors]
      @error_handler = options[:error_handler]
    end

    def handle(request)
      status, headers, response = @app.call(request.env)

      link, _ = @router.find_request_link(request)
      if validate?(status) && link
        full_body = ""
        response.each do |chunk|
          full_body << chunk
        end
        data = JSON.parse(full_body)
        Committee::ResponseValidator.new(link, validate_errors: validate_errors).call(status, headers, data)
      end

      [status, headers, response]
    rescue Committee::InvalidResponse
      @error_handler.call($!) if @error_handler
      raise if @raise
      @error_class.new(500, :invalid_response, $!.message).render
    rescue JSON::ParserError
      @error_handler.call($!) if @error_handler
      raise Committee::InvalidResponse if @raise
      @error_class.new(500, :invalid_response, "Response wasn't valid JSON.").render
    end

    def validate?(status)
      Committee::ResponseValidator.validate?(status, validate_errors: validate_errors)
    end
  end
end
