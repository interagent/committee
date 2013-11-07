module Rack::Committee
  class Lint < Base
    def call(env)
      status, headers, response = @app.call
      _, schema = @router.routes_request?(request)
      if schema
        data = MultiJson.decode(response)
        ResponseValidator.new(data, schema).call
      end
      [status, headers, response]
 #  rescue BadRequest
 #    render_error(400, :bad_request, $!.message)
 #  rescue InvalidParams
 #    render_error(422, :invalid_params, $!.message)
    end

    private

    def render_error(status, id, message)
      [status, { "Content-Type" => "application/json; charset=utf-8" },
        [MultiJson.encode(id: id, error: message)]]
    end
  end
end
