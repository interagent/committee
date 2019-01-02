module Committee
  class SchemaValidator::OpenAPI3::RequestValidator
    # @param [OpenAPIParser::RequestOperation] operation_object
    # @param [Committee::SchemaValidator::Option] validator_option
    def initialize(operation_object, validator_option:)
      @operation_object = operation_object
      @validator_option = validator_option
    end

    def call(request, params, headers)
      content_type = ::Committee::SchemaValidator.request_media_type(request)
      check_content_type(request, content_type) if @validator_option.check_content_type

      @operation_object.validate_request_params(params, headers, @validator_option)

      # TODO: support header
    end

    private

    def check_content_type(request, content_type)
      # support post, put, patch only
      return true unless request.post? || request.put? || request.patch?

      media_type = @operation_object.request_bodies_media_type(content_type)
      return true if media_type

      raise Committee::InvalidRequest, %{"Content-Type" request header must be set to "#{@operation_object}".}
    end
  end
end
