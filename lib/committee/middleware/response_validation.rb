module Committee::Middleware
  class ResponseValidation < Base
    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      _, type_schema = @router.routes_request?(request)
      if type_schema
        str = ""
        response.each { |s| str << s }
        Committee::ResponseValidator.new(MultiJson.decode(str), @schema, type_schema).call
      end
      [status, headers, response]
    rescue Committee::InvalidResponse
      render_error(500, :invalid_response, $!.message)
    rescue MultiJson::LoadError
      render_error(500, :invalid_response, "Response wasn't valid JSON.")
    end
  end
end
