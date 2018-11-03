class Committee::SchemaValidator
  class OpenAPI3
    def initialize(router, request, validator_option)
      @router = router
      @request = request
      @path_object = router.path_object(request)
      @validator_option = validator_option
    end

    def request_validate(_request)
      # TODO: implements
    end

    def link_exist?
      !@path_object.nil?
    end
  end
end