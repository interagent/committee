module Committee::Middleware
  class RequestValidation < Base
    def initialize(app, options={})
      super
      @prefix = options[:prefix]

      # deprecated
      @allow_extra = options[:allow_extra]
    end

    def call(env)
      request = Rack::Request.new(env)
      env[@params_key] = Committee::RequestUnpacker.new(request).call
      link, _ = @router.routes_request?(request, prefix: @prefix)
      if link
        Committee::ParamValidator.new.call(link, env[@params_key])
      end
      @app.call(env)
    rescue Committee::BadRequest
      render_error(400, :bad_request, $!.message)
    rescue Committee::Error
      render_error(422, :invalid_params, $!.message)
    rescue MultiJson::LoadError
      render_error(400, :invalid_params, "Request body wasn't valid JSON.")
    end
  end
end
