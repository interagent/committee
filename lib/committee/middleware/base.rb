# frozen_string_literal: true

module Committee
  module Middleware
    class Base
      def initialize(app, options = {})
        @app = app
        @options = build_options(options)

        @error_class = @options.error_class
        @error_handler = @options.error_handler
        @ignore_error = @options.ignore_error

        @raise = @options.raise_error
        @schema = self.class.get_schema(options)

        @router = @schema.build_router(options)
        @accept_request_filter = @options.accept_request_filter
      end

      def call(env)
        request = Rack::Request.new(env)

        if @router.includes_request?(request) && @accept_request_filter.call(request)
          handle(request)
        else
          @app.call(request.env)
        end
      end

      class << self
        def get_schema(options)
          schema = options[:schema]
          if !schema && options[:schema_path]
            # In the future, we could have `parser_options` as an exposed config?
            parser_options = options.key?(:strict_reference_validation) ? { strict_reference_validation: options[:strict_reference_validation] } : {}
            schema = Committee::Drivers::load_from_file(options[:schema_path], parser_options: parser_options)
          end
          raise(ArgumentError, "Committee: need option `schema` or `schema_path`") unless schema

          # Expect the type we want by now. If we don't have it, the user passed
          # something else non-standard in.
          if !schema.is_a?(Committee::Drivers::Schema)
            raise ArgumentError, "Committee: schema expected to be an instance of Committee::Drivers::Schema."
          end

          return schema
        end
      end

      private

      # Subclasses should override this method to use their specific Options class
      def build_options(options)
        Options::Base.from(options)
      end

      def build_schema_validator(request)
        @router.build_schema_validator(request)
      end
    end
  end
end
