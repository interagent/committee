module Rack::Committee
  class Lint < Base
    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      _, schema = @router.routes_request?(request)
      if schema
        str = ""
        response.each { |s| str << s }
        ResponseValidator.new(MultiJson.decode(str), schema).call
      end
      [status, headers, response]
    rescue MultiJson::LoadError
      render_error(500, :invalid_response, "Response wasn't valid JSON.")
    rescue InvalidResponse
      render_error(500, :invalid_response, $!.message)
    end

    private

    def render_error(status, id, message)
      [status, { "Content-Type" => "application/json; charset=utf-8" },
        [MultiJson.encode(id: id, error: message)]]
    end
  end
end
