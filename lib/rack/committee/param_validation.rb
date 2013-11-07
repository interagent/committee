module Rack::Committee
  class ParamValidation < Base
    def call(env)
      request = Rack::Request.new(env)
      env[@params_key] = RequestUnpacker.new(request).call
      link, _ = @router.routes_request?(request)
      if link
        ParamValidator.new(env[@params_key], link).call
      end
      @app.call(env)
    rescue BadRequest
      render_error(400, :bad_request, $!.message)
    rescue InvalidParams
      render_error(422, :invalid_params, $!.message)
    end

    private

    def render_error(status, id, message)
      [status, { "Content-Type" => "application/json; charset=utf-8" },
        [MultiJson.encode(id: id, error: message)]]
    end
  end
end
