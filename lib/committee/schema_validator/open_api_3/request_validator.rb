# frozen_string_literal: true

module Committee
  class SchemaValidator::OpenAPI3::RequestValidator
    # @param [SchemaValidator::OpenAPI3::OperationWrapper] operation_object
    # @param [Committee::SchemaValidator::Option] validator_option
    def initialize(operation_object, validator_option:)
      @operation_object = operation_object
      @validator_option = validator_option
    end

    def call(request, params, headers)
      content_type = ::Committee::SchemaValidator.request_media_type(request)
      check_content_type(request, content_type) if @validator_option.check_content_type

      @operation_object.validate_request_params(params, headers, @validator_option)
    end

    private

    def check_content_type(request, content_type)
      # support post, put, patch only
      return true unless request.post? || request.put? || request.patch?
      return true if @operation_object.valid_request_content_type?(content_type)

      raise Committee::InvalidRequest, %{"Content-Type" request header must be set to "#{@operation_object}".}
    end
  end
end
