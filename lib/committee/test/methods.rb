module Committee::Test
  module Methods
    def assert_schema_conform
      @schema ||= Committee::Middleware::Base.get_schema(committee_options)
      @router ||= @schema.build_router(committee_options)

      v = @router.build_schema_validator(request_object)

      unless v.link_exist?
        response = "`#{request_object.request_method} #{request_object.path_info}` undefined in schema."
        raise Committee::InvalidResponse.new(response)
      end

      status, headers, body = response_data
      v.response_validate(status, headers, [body], true) if validate_response?(status)
    end

    def committee_options
      raise "please set options"
    end

    def request_object
      raise "please set object like 'last_request'"
    end

    def response_data
      raise "please set response data like 'last_response.status, last_response.headers, last_response.body'"
    end

    def validate_response?(status)
      Committee::Middleware::ResponseValidation.validate?(status, false)
    end
  end
end
