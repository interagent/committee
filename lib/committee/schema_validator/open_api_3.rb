class Committee::SchemaValidator
  class OpenAPI3
    def initialize(router, request, validator_option)
      @router = router
      @request = request
      @operation_object = router.operation_object(request)
      @validator_option = validator_option
    end

    def request_validate(request)
      path_params = validator_option.coerce_path_params ? coerce_path_params : {}

      # TODO: coerce_query_params

      request_unpack(request)

      request.env[validator_option.params_key]&.merge!(path_params) unless path_params.blank?

      request_schema_validation(request)
      # parameter_coerce!(request, link, validator_option.params_key)
      # parameter_coerce!(request, link, "rack.request.query_hash") if link_exist? && !request.GET.nil? && !link.schema.nil?
    end

    def response_validate(status, headers, response)
      full_body = ""
      response.each do |chunk|
        full_body << chunk
      end
      data = JSON.parse(full_body)
      Committee::SchemaValidator::OpenAPI3::ResponseValidator.new(@operation_object, validator_option).call(status, headers, data)
    end

    def link_exist?
      !@operation_object.nil?
    end

    def coerce_form_params(parameter)
      return unless @operation_object
      Committee::SchemaValidator::OpenAPI3::StringParamsCoercer.new(parameter, @operation_object, @validator_option).call!
    end

    private

    attr_reader :validator_option

    def coerce_path_params
      return {} unless link_exist?
      Committee::SchemaValidator::OpenAPI3::StringPathParamsCoercer.new(@operation_object.path_params, @operation_object, validator_option).call!
    end

    def request_schema_validation(request)
      return unless @operation_object

      validator = Committee::SchemaValidator::OpenAPI3::RequestValidator.new(@operation_object,
                                                                             check_content_type: validator_option.check_content_type,
                                                                             check_header: validator_option.check_header)
      validator.call(request, request.env[validator_option.params_key], request.env[validator_option.headers_key])
    end

    def request_unpack(request)
      request.env[validator_option.params_key], request.env[validator_option.headers_key] = Committee::RequestUnpacker.new(
          request,
          allow_form_params:  validator_option.allow_form_params,
          allow_query_params: validator_option.allow_query_params,
          coerce_form_params: validator_option.coerce_form_params,
          optimistic_json:    validator_option.optimistic_json,
          schema_validator:   self
      ).call
    end
  end
end