module Committee::Middleware
  class ResponseValidation < Base
    attr_reader :validate_success_only

    def initialize(app, options = {})
      super
      @validate_success_only = @schema.validator_option.validate_success_only
    end

    def handle(request)
      status, headers, response = @app.call(request.env)

      v = build_schema_validator(request)
      v.response_validate(status, headers, response) if v.link_exist? && self.class.validate?(status, validate_success_only)

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

    class << self
      def validate?(status, validate_success_only)
        status != 204 && (!validate_success_only || (200...300).include?(status))
      end
    end
  end
end
