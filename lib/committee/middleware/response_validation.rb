# frozen_string_literal: true

module Committee
  module Middleware
    class ResponseValidation < Base
      attr_reader :validate_success_only

      def initialize(app, options = {})
        super
        @strict = options[:strict]
        @validate_success_only = @schema.validator_option.validate_success_only
      end

      def handle(request)
        status, headers, response = @app.call(request.env)

        begin
          v = build_schema_validator(request)
          v.response_validate(status, headers, response, @strict) if v.link_exist? && self.class.validate?(status, validate_success_only)

        rescue Committee::InvalidResponse
          handle_exception($!, request.env)

          raise if @raise
          return @error_class.new(500, :invalid_response, $!.message).render unless @ignore_error
        rescue JSON::ParserError
          handle_exception($!, request.env)

          raise Committee::InvalidResponse if @raise
          return @error_class.new(500, :invalid_response, "Response wasn't valid JSON.").render unless @ignore_error
        end

        [status, headers, response]
      end

      class << self
        def validate?(status, validate_success_only)
          case status
          when 204
            false
          when 200..299
            true
          when 304
            false
          else
            !validate_success_only
          end
        end
      end

      private

      def handle_exception(e, env)
        @error_handler.call(e, env) if @error_handler
      end
    end
  end
end
