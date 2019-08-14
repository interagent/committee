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
        schema_validator = build_schema_validator(request)
        schema_validator.request_validate(request)

        raise Committee::NotFound, "That request method and path combination isn't defined." if !schema_validator.link_exist? && @strict

        @app.call(request.env)
      rescue Committee::BadRequest, Committee::InvalidRequest
        handle_exception($!, request.env)
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
        handle_exception($!, request.env)
        raise Committee::InvalidRequest if @raise
        @error_class.new(400, :bad_request, "Request body wasn't valid JSON.").render
      end

      private

      def handle_exception(e, env)
        return unless @error_handler

        if @error_handler.arity > 1
          @error_handler.call(e, env)
        else
          warn <<-MESSAGE
          [DEPRECATION] Using `error_handler.call(exception)` is deprecated and will be change to
            `error_handler.call(exception, request.env)` in next major version.
          MESSAGE

          @error_handler.call(e)
        end
      end
    end
  end
end
