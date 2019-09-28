# frozen_string_literal: true

module Committee
  module SchemaValidator
    class OpenAPI3
      class ResponseValidator
        attr_reader :validate_success_only

        # @param [Committee::SchemaValidator::Options] validator_option
        # @param [Committee::SchemaValidator::OpenAPI3::OperationWrapper] operation_wrapper
        def initialize(operation_wrapper, validator_option)
          @operation_wrapper = operation_wrapper
          @validate_success_only = validator_option.validate_success_only
          @check_header = validator_option.check_header
        end

        def call(status, headers, response_data, strict)
          return unless Committee::Middleware::ResponseValidation.validate?(status, validate_success_only)

          operation_wrapper.validate_response_params(status, headers, response_data, strict, check_header)
        end

        private

        attr_reader :operation_wrapper, :check_header
      end
    end
  end
end
