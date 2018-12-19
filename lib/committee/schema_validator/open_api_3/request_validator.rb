module Committee
  class SchemaValidator::OpenAPI3::RequestValidator
    def initialize(operation_object, validator_option:)
      @operation_object = operation_object
      @validator_option = validator_option
    end

    def call(request, params, headers)
      # TODO: support @check_content_type
      # check_content_type!(request, params) if @check_content_type

      @operation_object.validate_request_params(params, @validator_option)

      # TODO: support header
    end
  end
end
