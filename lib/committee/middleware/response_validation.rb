module Committee::Middleware
  class ResponseValidation < Base
    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      link_schema, type_schema = @router.routes_request?(request)
      if type_schema
        check_content_type!(headers)
        str = response.reduce("") { |str, s| str << s }
        Committee::ResponseValidator.new(
          MultiJson.decode(str),
          @schema,
          link_schema,
          type_schema
        ).call
      end
      [status, headers, response]
    rescue Committee::InvalidResponse
      render_error(500, :invalid_response, $!.message)
    rescue MultiJson::LoadError
      render_error(500, :invalid_response, "Response wasn't valid JSON.")
    end

    private

    def check_content_type!(headers)
      unless headers["Content-Type"] =~ %r{application/json}
        raise Committee::InvalidResponse,
          %{"Content-Type" response header must be set to "application/json".}
      end
    end
  end
end
