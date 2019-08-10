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
        @error_handler.call($!) if @error_handler
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
        @error_handler.call($!) if @error_handler
        raise Committee::InvalidRequest if @raise
        @error_class.new(400, :bad_request, "Request body wasn't valid JSON.").render
      end
    end
  end
end
