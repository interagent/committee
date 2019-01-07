module Committee
  class SchemaValidator::OpenAPI3::ResponseValidator
    attr_reader :validate_errors

    # @param [Committee::SchemaValidator::Options] validator_option
    # @param [Committee::SchemaValidator::OpenAPI3::OperationWrapper] operation_wrapper
    def initialize(operation_wrapper, validator_option)
      @operation_wrapper = operation_wrapper
      @validate_errors = validator_option.validate_errors
      @check_header = validator_option.check_header
    end

    def call(status, headers, response_data, strict)
      return unless Committee::Middleware::ResponseValidation.validate?(status, validate_errors)

      #content_type = headers['Content-Type'].to_s.split(";").first.to_s
      operation_wrapper.validate_response_params(status, headers, response_data, strict, check_header)
    end

    private

    attr_reader :operation_wrapper, :check_header
  end
end
