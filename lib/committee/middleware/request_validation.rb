# frozen_string_literal: true

module Committee
  module Middleware
    class RequestValidation < Base
      def initialize(app, options={})
        super

        @strict  = options[:strict]

        # deprecated
        @allow_extra = options[:allow_extra]
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
        return unless @error_handler

        if @error_handler.arity > 1
          @error_handler.call(e, env)
        else
          Committee.warn_deprecated('Using `error_handler.call(exception)` is deprecated and will be change to `error_handler.call(exception, request.env)` in next major version.')
          @error_handler.call(e)
        end
      end
    end
  end
end
