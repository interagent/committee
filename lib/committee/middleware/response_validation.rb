module Committee::Middleware
  class ResponseValidation < Base
    attr_reader :validate_success_only

    def initialize(app, options = {})
      super
      @validate_success_only = @schema.validator_option.validate_success_only

      @ignore_error = options.fetch(:ignore_error, false)
      @error_handler = options[:error_handler]
    end

    def handle(request)
      begin
        status, headers, response = @app.call(request.env)

        v = build_schema_validator(request)
        v.response_validate(status, headers, response) if v.link_exist? && self.class.validate?(status, validate_success_only)
      rescue Committee::InvalidResponse
        @error_handler.call($!) if @error_handler
        raise if @raise
        return @error_class.new(500, :invalid_response, $!.message).render unless @ignore_error
      rescue JSON::ParserError
        @error_handler.call($!) if @error_handler
        raise Committee::InvalidResponse if @raise
        return @error_class.new(500, :invalid_response, "Response wasn't valid JSON.").render unless @ignore_error
      end

      [status, headers, response]
    end

    class << self
      def validate?(status, validate_success_only)
        status != 204 && (!validate_success_only || (200...300).include?(status))
      end
    end
  end
end
