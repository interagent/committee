module Committee
  class SchemaValidator::OpenAPI3::RequestValidator
    def initialize(operation_object, check_content_type:, check_header:)
      @operation_object = operation_object
      @check_header = check_header
      @check_content_type = check_content_type
    end

    def call(request, params, headers)
      # TODO: support @check_content_type
      # check_content_type!(request, params) if @check_content_type

      @operation_object.validate(params)

      # TODO: support header
    end
  end
end
