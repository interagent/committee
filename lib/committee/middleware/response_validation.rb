# frozen_string_literal: true

module Committee
  module Middleware
    class ResponseValidation < Base
      attr_reader :validate_success_only

      def initialize(app, options = {})
        super
        @strict = options[:strict]
        @validate_success_only = @schema.validator_option.validate_success_only
        @streaming_content_parsers = options[:streaming_content_parsers] || {}
      end

      def handle(request)
        status, headers, response = @app.call(request.env)

        streaming_content_parser = retrieve_streaming_content_parser(headers)

        if streaming_content_parser
          response = Rack::BodyProxy.new(response) do
            begin
              validate(request, status, headers, response, streaming_content_parser)
            rescue => e
              handle_exception(e, request.env)

              raise e if @raise
            end
          end
        else
          begin
            validate(request, status, headers, response)
          rescue Committee::InvalidResponse
            handle_exception($!, request.env)

            raise if @raise
            return @error_class.new(500, :invalid_response, $!.message).render unless @ignore_error
          rescue JSON::ParserError
            handle_exception($!, request.env)

            raise Committee::InvalidResponse if @raise
            return @error_class.new(500, :invalid_response, "Response wasn't valid JSON.").render unless @ignore_error
          end
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

      def validate(request, status, headers, response, streaming_content_parser = nil)
        v = build_schema_validator(request)
        if v.link_exist? && self.class.validate?(status, validate_success_only)
          v.response_validate(status, headers, response, @strict, streaming_content_parser)
        end
      end

      def retrieve_streaming_content_parser(headers)
        content_type_key = headers.keys.detect { |k| k.casecmp?('Content-Type') }
        content_type = headers.fetch(content_type_key, nil)
        @streaming_content_parsers[content_type]
      end

      def handle_exception(e, env)
        @error_handler.call(e, env) if @error_handler
      end
    end
  end
end
