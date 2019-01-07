module Committee
  class SchemaValidator::OpenAPI3::ResponseValidator
    attr_reader :validate_errors

    # @param [Committee::SchemaValidator::OpenAPI3::OperationWrapper] operation_wrapper
    def initialize(operation_wrapper, validator_option)
      @operation_wrapper = operation_wrapper
      @validate_errors = validator_option.validate_errors
    end

    def call(status, headers, data, strict)
      return unless Committee::Middleware::ResponseValidation.validate?(status, validate_errors)

      content_type = headers['Content-Type'].to_s.split(";").first.to_s
      operation_wrapper.validate_response_params(status, content_type, data, strict)
    end

    private

    # @return [Committee::SchemaValidator::OpenAPI3::OperationWrapper]
    attr_reader :operation_wrapper
  end
end
