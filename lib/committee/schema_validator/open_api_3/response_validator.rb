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
          @allow_empty_date_and_datetime = validator_option.allow_empty_date_and_datetime
        end

        def call(status, headers, response_data, strict)
          return unless validate?(status)

          validator_options = { allow_empty_date_and_datetime: @allow_empty_date_and_datetime }

          operation_wrapper.validate_response_params(status, headers, response_data, strict, check_header, validator_options: validator_options)
        end

        def validate?(status)
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

        private

        attr_reader :operation_wrapper, :check_header
      end
    end
  end
end
