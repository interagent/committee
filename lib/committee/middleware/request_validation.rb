# frozen_string_literal: true

module Committee
  module Middleware
    class RequestValidation < Base
      def initialize(app, options={})
        super

        @strict  = options[:strict]
      end

      def handle(request)
        begin
          schema_validator = build_schema_validator(request)
          schema_validator.request_validate(request)

          raise Committee::NotFound, "That request method and path combination isn't defined." if !schema_validator.link_exist? && @strict
        rescue Committee::BadRequest, Committee::InvalidRequest
          handle_exception($!, request.env)
          raise if @raise
          return @error_class.new(400, :bad_request, $!.message, request).render unless @ignore_error
        rescue Committee::NotFound => e
          raise if @raise
          return @error_class.new(404, :not_found, e.message, request).render unless @ignore_error
        rescue JSON::ParserError
          handle_exception($!, request.env)
          raise Committee::InvalidRequest if @raise
          return @error_class.new(400, :bad_request, "Request body wasn't valid JSON.", request).render unless @ignore_error
        end

        @app.call(request.env)
      end

      private

      def handle_exception(e, env)
        @error_handler.call(e, env) if @error_handler
      end
    end
  end
end
