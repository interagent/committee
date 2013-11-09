module Committee::Middleware
  class RequestValidation < Base
    def call(env)
      request = Rack::Request.new(env)
      env[@params_key] = Committee::RequestUnpacker.new(request).call
      link, _ = @router.routes_request?(request)
      if link
        Committee::ParamValidator.new(env[@params_key], @schema, link).call
      end
      @app.call(env)
    rescue Committee::BadRequest
      render_error(400, :bad_request, $!.message)
    rescue Committee::InvalidParams
      render_error(422, :invalid_params, $!.message)
    end
  end
end
