class Committee::SchemaValidator
  class OpenAPI3
    def initialize(router, request, validator_option)
      @router = router
      @request = request
      @operation_object = router.operation_object(request)
      @validator_option = validator_option
    end

    def request_validate(_request)
      # TODO: implements
    end

    def link_exist?
      !@operation_object.nil?
    end

    def coerce_form_params(parameter)
      return unless @operation_object
      Committee::SchemaValidator::OpenAPI3::StringParamsCoercer.new(parameter, @operation_object, @validator_option).call!
    end
  end
end