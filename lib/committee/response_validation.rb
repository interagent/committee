module Committee
  class ResponseValidation < Base
    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      _, type_schema = @router.routes_request?(request)
      if type_schema
        str = ""
        response.each { |s| str << s }
        ResponseValidator.new(MultiJson.decode(str), @schema, type_schema).call
      end
      [status, headers, response]
    rescue MultiJson::LoadError
      render_error(500, :invalid_response, "Response wasn't valid JSON.")
    rescue InvalidResponse
      render_error(500, :invalid_response, $!.message)
    end
  end
end
