# frozen_string_literal: true

module Committee
  module SchemaValidator
    class OpenAPI3
      class Router
        # @param [Committee::SchemaValidator::Option] validator_option
        def initialize(schema, validator_option)
          @schema = schema
          @prefix_regexp = ::Committee::SchemaValidator.build_prefix_regexp(validator_option.prefix)
          @validator_option = validator_option
        end

        def includes_request?(request)
          return true unless @prefix_regexp

          prefix_request?(request)
        end

        def build_schema_validator(request)
          Committee::SchemaValidator::OpenAPI3.new(self, request, @validator_option)
        end

        def operation_object(request)
          return nil unless includes_request?(request)

          path = request.path
          path = path.gsub(@prefix_regexp, '') if @prefix_regexp

          request_method = request.request_method.downcase

          @schema.operation_object(path, request_method)
        end

        private

        def prefix_request?(request)
          return false unless @prefix_regexp

          request.path =~ @prefix_regexp
        end
      end
    end
  end
end
