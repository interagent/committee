module Committee
  class SchemaValidator::OpenAPI3::ResponseValidator
    attr_reader :validate_errors

    # @param [Committee::SchemaValidator::OpenAPI3::OperationWrapper] operation_wrapper
    def initialize(operation_wrapper, validator_option)
      @operation_wrapper = operation_wrapper
      @validate_errors = validator_option.validate_errors
    end

    def self.validate?(status, options = {})
      validate_errors = options[:validate_errors]

      status != 204 && (validate_errors || (200...300).include?(status))
    end

    def call(status, headers, data)
      return unless self.class.validate?(status, validate_errors: validate_errors)

      content_type = headers['Content-Type'].to_s.split(";").first.to_s
      operation_wrapper.validate_response_params(status, content_type, data)
    end

    private

    # @return [Committee::SchemaValidator::OpenAPI3::OperationWrapper]
    attr_reader :operation_wrapper

    def check_content_type!(response)
      # TODO: fix
      # OpenAPI3 support multi content type definitions, so we should get OperationObject by content type and this function don't need
      # We should support if content exist and not exist content-type definition, raise error (if not exist content, we don't raise error)
    end
  end
end
